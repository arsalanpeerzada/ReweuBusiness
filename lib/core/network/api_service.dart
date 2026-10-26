import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import '../storage/storage_service.dart';

class ApiService {
  final Dio dio;
  final StorageService storageService;
  static void Function()? onSessionExpired;
  String? _authToken;

  ApiService({
    required this.storageService,
    Dio? dioClient,
  }) : dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'ngrok-skip-browser-warning': 'true',
                },
              ),
            ) {
    _setupInterceptors();
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_authToken == null || _authToken!.isEmpty) {
            _authToken = await storageService.getToken();
          }
          if (_authToken != null && _authToken!.isNotEmpty) {
            final cleanToken = _authToken!.startsWith('Bearer ')
                ? _authToken!.substring(7).trim()
                : _authToken!.trim();
            options.headers['Authorization'] = 'Bearer $cleanToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final contentType = response.headers.value('content-type') ?? '';
          if (contentType.contains('text/html') && response.data is String) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                message: 'Received HTML instead of JSON from ngrok gateway.',
              ),
            );
            return;
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final isLogin = error.requestOptions.path.contains('/login');
            if (!isLogin) {
              clearAuthToken();
              await storageService.deleteToken();
              onSessionExpired?.call();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  String formatDioError(DioException error) {
    if (error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          return data['message'].toString();
        }
        if (data['error'] != null && data['error'].toString().isNotEmpty) {
          return data['error'].toString();
        }
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your network.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Please check your internet.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401) return 'Invalid email or password.';
        if (code == 403) return 'Access denied. Account not authorized.';
        if (code == 404) return 'Requested resource not found.';
        return 'Server returned error status ($code).';
      default:
        return error.message ?? 'An unexpected network error occurred.';
    }
  }

  // User Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw Exception('Invalid response received from server.');
    } on DioException catch (e) {
      throw Exception(formatDioError(e));
    }
  }

  // User Profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await dio.get(ApiConstants.userProfile);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
      return data is Map<String, dynamic> ? data : {};
    } on DioException catch (e) {
      throw Exception(formatDioError(e));
    }
  }

  // Get User Businesses
  Future<List<dynamic>> getUserBusinesses() async {
    try {
      // 1. First fetch user-assigned businesses (which the user has permission for)
      try {
        final response = await dio.get(ApiConstants.myBusinesses);
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] != null) {
          final inner = data['data'];
          if (inner is List && inner.isNotEmpty) {
            return inner;
          }
        } else if (data is List && data.isNotEmpty) {
          return data;
        }
      } catch (_) {}

      // 2. Fallback to assigned branches (for Branch Managers / Branch Admins)
      try {
        final response = await dio.get(
          ApiConstants.myBranches,
          queryParameters: {'page': 0, 'size': 50, 'sortBy': 'Name'},
        );
        final data = response.data;
        List<dynamic> branchList = [];
        if (data is Map<String, dynamic>) {
          if (data['data'] != null) {
            final inner = data['data'];
            if (inner is Map<String, dynamic> && inner['content'] is List) {
              branchList = inner['content'] as List<dynamic>;
            } else if (inner is List) {
              branchList = inner;
            }
          } else if (data['content'] is List) {
            branchList = data['content'] as List<dynamic>;
          }
        } else if (data is List) {
          branchList = data;
        }

        if (branchList.isNotEmpty) {
          final Map<int, Map<String, dynamic>> extractedBusinesses = {};
          for (final b in branchList) {
            if (b is Map<String, dynamic>) {
              final bId = b['businessId'] is int
                  ? b['businessId'] as int
                  : int.tryParse(b['businessId']?.toString() ?? '');
              if (bId != null && bId > 0 && !extractedBusinesses.containsKey(bId)) {
                extractedBusinesses[bId] = {
                  'id': bId,
                  'name': b['businessName'] ?? b['name'] ?? 'Business $bId',
                  'overAllRating': b['rating'] ?? 0.0,
                  'logoUrl': b['logoUrl'],
                };
              }
            }
          }
          if (extractedBusinesses.isNotEmpty) {
            return extractedBusinesses.values.toList();
          }
        }
      } catch (_) {}

      // 3. Fallback to all businesses ONLY if user is a SUPER_ADMIN
      if (storageService.isSuperAdmin()) {
        try {
          final response = await dio.get(ApiConstants.businesses);
          final data = response.data;
          if (data is Map<String, dynamic> && data['data'] != null) {
            final inner = data['data'];
            if (inner is List) {
              return inner;
            } else if (inner is Map<String, dynamic> && inner['content'] is List) {
              return inner['content'] as List<dynamic>;
            }
          } else if (data is List) {
            return data;
          }
        } catch (_) {}
      }

      return [];
    } on DioException catch (e) {
      throw Exception(formatDioError(e));
    }
  }

  // Business Incidents List
  Future<List<dynamic>> getBusinessIncidents(
    int businessId, {
    int? branchId,
    String? status,
    int page = 0,
    int size = 30,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (branchId != null) queryParams['branchId'] = branchId;
      if (status != null && status != 'ALL') queryParams['status'] = status;

      final response = await dio.get(
        '${ApiConstants.incidentsByBusiness}/$businessId',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic> && innerData['content'] != null) {
          return innerData['content'] as List<dynamic>;
        } else if (innerData is List) {
          return innerData;
        }
      }
      return [];
    } on DioException catch (e) {
      throw Exception(formatDioError(e));
    }
  }

  // Incident Details
  Future<Map<String, dynamic>> getIncidentDetails(int id) async {
    try {
      final response = await dio.get('${ApiConstants.incidentDetails}/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception('Failed to load incident details');
    } on DioException catch (e) {
      throw Exception(formatDioError(e));
    }
  }

  // Add Comment
  Future<Map<String, dynamic>> addComment(int id, String comment) async {
    try {
      final userId = storageService.getUserId() ?? 0;
      final response = await dio.post(
        '${ApiConstants.incidentDetails}/$id/comments',
        data: {'userId': userId, 'message': comment, 'comment': comment},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
      return data is Map<String, dynamic> ? data : {};
    } on DioException catch (e) {
      throw Exception(formatDioError(e));
    }
  }

  // Update Status & Service Recovery
  Future<Map<String, dynamic>> updateStatus(
    int id, {
    required String status,
    String? resolutionSummary,
    bool sendVoucher = false,
    double? voucherAmount,
  }) async {
    try {
      final userId = storageService.getUserId() ?? 0;
      final queryParams = <String, dynamic>{
        'status': status,
        'userId': userId,
      };
      if (resolutionSummary != null) {
        queryParams['resolutionSummary'] = resolutionSummary;
      }
      if (sendVoucher) queryParams['sendVoucher'] = sendVoucher;
      if (voucherAmount != null) queryParams['voucherAmount'] = voucherAmount;

      final body = <String, dynamic>{
        'status': status,
        'userId': userId,
        'sendVoucher': sendVoucher,
        'resolutionSummary': ?resolutionSummary,
        'voucherAmount': ?voucherAmount,
      };

      final response = await dio.patch(
        '${ApiConstants.incidentDetails}/$id/status',
        queryParameters: queryParams,
        data: body,
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      throw Exception(formatDioError(e));
    }
  }

  // Device Token Registration
  Future<void> registerDeviceToken({
    required String deviceToken,
    required String deviceName,
    required String osType,
    String? osVersion,
    String? appVersion,
  }) async {
    try {
      await dio.post(
        ApiConstants.registerDevice,
        data: {
          'deviceToken': deviceToken,
          'deviceName': deviceName,
          'deviceType': 'mobile',
          'osType': osType,
          'osVersion': osVersion,
          'appVersion': appVersion,
        },
      );
    } on DioException catch (e) {
      throw Exception(formatDioError(e));
    }
  }

  // Device Token Unregistration
  Future<void> unregisterDeviceToken(String deviceToken) async {
    try {
      await dio.delete(
        ApiConstants.unregisterDevice,
        queryParameters: {'deviceToken': deviceToken},
      );
    } on DioException catch (e) {
      throw Exception(formatDioError(e));
    }
  }
}
