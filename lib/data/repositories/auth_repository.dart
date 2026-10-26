import '../models/auth_models.dart';
import '../../core/network/api_service.dart';
import '../../core/storage/storage_service.dart';

class AuthRepository {
  final ApiService apiService;
  final StorageService storageService;

  AuthRepository({
    required this.apiService,
    required this.storageService,
  });

  Future<LoginUserResponse> login({
    required String email,
    required String password,
  }) async {
    final rawResponse = await apiService.login(email.trim(), password);

    Map<String, dynamic> data;
    if (rawResponse['data'] != null && rawResponse['data'] is Map<String, dynamic>) {
      data = rawResponse['data'] as Map<String, dynamic>;
    } else {
      data = rawResponse;
    }

    final loginUser = LoginUserResponse.fromJson(data);

    // Save token securely & set in API service
    await storageService.saveToken(loginUser.token);
    apiService.setAuthToken(loginUser.token);

    // Save initial user context including roles
    await storageService.saveUserContext(
      userId: loginUser.id,
      userEmail: loginUser.email,
      userName: '${loginUser.firstName} ${loginUser.lastName}'.trim(),
      roles: loginUser.roles,
    );

    // Attempt to discover the user's business(es)
    int? activeBusinessId;
    try {
      final businesses = await getUserBusinesses();
      if (businesses.isNotEmpty) {
        activeBusinessId = businesses.first.id;
      }
    } catch (_) {
      // Non-fatal if business list cannot be retrieved immediately
    }

    await storageService.saveUserContext(
      userId: loginUser.id,
      businessId: activeBusinessId,
      userEmail: loginUser.email,
      userName: '${loginUser.firstName} ${loginUser.lastName}'.trim(),
      roles: loginUser.roles,
    );

    return loginUser;
  }

  Future<List<BusinessSummary>> getUserBusinesses() async {
    final rawList = await apiService.getUserBusinesses();
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((json) => BusinessSummary.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      return await apiService.getUserProfile();
    } catch (_) {
      return {};
    }
  }

  Future<void> switchBusiness(int businessId) async {
    final userId = storageService.getUserId() ?? 0;
    await storageService.saveUserContext(
      userId: userId,
      businessId: businessId,
      userEmail: storageService.getUserEmail(),
      userName: storageService.getUserName(),
      roles: storageService.getRoles(),
    );
  }

  Future<void> logout() async {
    apiService.clearAuthToken();
    await storageService.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await storageService.getToken();
    return token != null && token.isNotEmpty;
  }
}
