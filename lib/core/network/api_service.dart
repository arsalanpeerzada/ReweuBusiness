import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../config/api_constants.dart';
import '../storage/storage_service.dart';
import 'api_exception.dart';

class ApiService {
  final Dio dio;
  final StorageService storageService;
  static void Function()? onSessionExpired;
  String? _authToken;
  bool _sessionExpiryInFlight = false;

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
                },
              ),
            ) {
    _setupInterceptors();
  }

  void setAuthToken(String token) {
    _authToken = token;
    _sessionExpiryInFlight = false;
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
                message: 'Received HTML instead of JSON.',
              ),
            );
            return;
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final isLogin = error.requestOptions.path.contains('/login');
            if (!isLogin && !_sessionExpiryInFlight) {
              _sessionExpiryInFlight = true;
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

  ApiException toApiException(DioException error) {
    final code = error.response?.statusCode;
    String? serverMessage;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] ?? data['error'];
      if (msg != null && msg.toString().isNotEmpty) {
        serverMessage = msg.toString();
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(ApiErrorKind.timeout, 'errors.timeout'.tr());
      case DioExceptionType.connectionError:
        return ApiException(ApiErrorKind.network, 'errors.network'.tr());
      case DioExceptionType.badResponse:
        if (code == 401) {
          final isLogin = error.requestOptions.path.contains('/login');
          return ApiException(
            ApiErrorKind.unauthorised,
            isLogin ? 'errors.invalid_credentials'.tr() : 'errors.session_expired'.tr(),
            statusCode: code,
          );
        }
        if (code == 403) {
          return ApiException(ApiErrorKind.forbidden, 'errors.forbidden'.tr(), statusCode: code);
        }
        if (code == 404) {
          return ApiException(ApiErrorKind.notFound, 'errors.not_found'.tr(), statusCode: code);
        }
        if (code != null && code >= 400 && code < 500) {
          return ApiException(
            ApiErrorKind.validation,
            serverMessage ?? 'errors.request_rejected'.tr(),
            statusCode: code,
          );
        }
        return ApiException(ApiErrorKind.server, 'errors.server'.tr(), statusCode: code);
      default:
        return ApiException(ApiErrorKind.unknown, 'errors.unknown'.tr(), statusCode: code);
    }
  }

  /// Unwraps the backend's `{status, message, path, data}` envelope.
  dynamic _unwrap(dynamic body) {
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  List<dynamic> _asContentList(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic> && value['content'] is List) {
      return value['content'] as List<dynamic>;
    }
    return const [];
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
      throw ApiException(ApiErrorKind.server, 'errors.server'.tr());
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  // User Profile
  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final response = await dio.get(
        ApiConstants.userProfile,
        queryParameters: {'id': userId},
      );
      return _asMap(_unwrap(response.data));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  // Get User Businesses
  Future<List<dynamic>> getUserBusinesses() async {
    ApiException? lastError;

    // 1. Businesses the user owns or administers
    try {
      final response = await dio.get(ApiConstants.myBusinesses);
      final list = _asContentList(_unwrap(response.data));
      if (list.isNotEmpty) return list;
    } on DioException catch (e) {
      lastError = toApiException(e);
    }

    // 2. Fall back to assigned branches (Branch Managers / Branch Admins)
    try {
      final branchList = await getMyBranches();
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
    } on ApiException catch (e) {
      lastError = e;
    }

    // 3. All businesses, only for SUPER_ADMIN
    if (storageService.isSuperAdmin()) {
      try {
        final response = await dio.get(ApiConstants.businesses);
        return _asContentList(_unwrap(response.data));
      } on DioException catch (e) {
        lastError = toApiException(e);
      }
    }

    if (lastError != null && lastError.isOffline) throw lastError;
    return [];
  }

  // Branches the user can access (all businesses)
  Future<List<dynamic>> getMyBranches() async {
    try {
      final response = await dio.get(
        ApiConstants.myBranches,
        queryParameters: {
          'page': 0,
          'size': AppConfig.branchPageSize,
          'sortBy': 'Name',
        },
      );
      return _asContentList(_unwrap(response.data));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  // Business Incidents (one page)
  Future<Map<String, dynamic>> getBusinessIncidents(
    int businessId, {
    int? branchId,
    String? status,
    int page = 0,
    int size = AppConfig.incidentPageSize,
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

      final inner = _unwrap(response.data);
      if (inner is List) {
        return {'content': inner, 'last': true};
      }
      final map = _asMap(inner);
      return {
        'content': map['content'] is List ? map['content'] : const [],
        'last': map['last'] ?? true,
        'totalElements': map['totalElements'],
      };
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  // Incident Details
  Future<Map<String, dynamic>> getIncidentDetails(int id) async {
    try {
      final response = await dio.get('${ApiConstants.incidentDetails}/$id');
      final data = _unwrap(response.data);
      if (data is Map<String, dynamic>) return data;
      throw ApiException(ApiErrorKind.server, 'errors.server'.tr());
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  // Add internal comment. The backend takes the author from the token.
  Future<Map<String, dynamic>> addComment(int id, String comment) async {
    try {
      final response = await dio.post(
        '${ApiConstants.incidentDetails}/$id/comments',
        data: {'comment': comment},
      );
      return _asMap(_unwrap(response.data));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  // Update Status & Service Recovery. The backend reads these as query
  // parameters and takes the acting user from the token.
  Future<Map<String, dynamic>> updateStatus(
    int id, {
    required String status,
    String? resolutionSummary,
    bool sendVoucher = false,
    double? voucherAmount,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'status': status,
        'sendVoucher': sendVoucher,
        'resolutionSummary': ?resolutionSummary,
        'voucherAmount': ?voucherAmount,
      };

      final response = await dio.patch(
        '${ApiConstants.incidentDetails}/$id/status',
        queryParameters: queryParams,
      );
      return _asMap(_unwrap(response.data));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  // Incident analytics (KPIs, trends, staff and branch performance)
  Future<Map<String, dynamic>> getIncidentAnalytics(
    int businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await dio.get(
        '${ApiConstants.incidentAnalytics}/$businessId',
        queryParameters: {
          if (startDate != null) 'startDate': _isoLocal(startDate),
          if (endDate != null) 'endDate': _isoLocal(endDate),
        },
      );
      return _asMap(_unwrap(response.data));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  String _isoLocal(DateTime dt) =>
      DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(dt);

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
      throw toApiException(e);
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
      throw toApiException(e);
    }
  }
}
