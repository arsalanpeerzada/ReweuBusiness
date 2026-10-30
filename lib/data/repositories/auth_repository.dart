import '../models/auth_models.dart';
import '../../core/network/api_service.dart';
import '../../core/storage/storage_service.dart';

class AuthRepository {
  final ApiService apiService;
  final StorageService storageService;

  /// Runs after a successful sign-in (for example push registration).
  Future<void> Function()? onSignedIn;

  /// Runs before the session is cleared, while the token is still valid
  /// (for example unregistering this device from push).
  Future<void> Function()? onBeforeSignOut;

  AuthRepository({
    required this.apiService,
    required this.storageService,
    this.onSignedIn,
    this.onBeforeSignOut,
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
      // Non-fatal: the feed retries business discovery on open.
    }

    await storageService.saveUserContext(
      userId: loginUser.id,
      businessId: activeBusinessId,
      userEmail: loginUser.email,
      userName: '${loginUser.firstName} ${loginUser.lastName}'.trim(),
      roles: loginUser.roles,
    );

    try {
      await onSignedIn?.call();
    } catch (_) {}

    return loginUser;
  }

  Future<List<BusinessSummary>> getUserBusinesses() async {
    final rawList = await apiService.getUserBusinesses();
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((json) => BusinessSummary.fromJson(json))
        .toList();
  }

  /// Branches of [businessId] the signed-in user can access.
  Future<List<BranchSummary>> getBranches(int businessId) async {
    final rawList = await apiService.getMyBranches();
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(BranchSummary.fromJson)
        .where((b) => b.businessId == businessId && b.id > 0)
        .toList();
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final userId = storageService.getUserId();
    if (userId == null || userId <= 0) return {};
    return apiService.getUserProfile(userId);
  }

  Future<void> switchBusiness(int businessId) async {
    final userId = storageService.getUserId() ?? 0;
    await storageService.saveUserContext(
      userId: userId,
      businessId: businessId,
      // A branch belongs to one business, so reset the branch filter.
      branchId: null,
      userEmail: storageService.getUserEmail(),
      userName: storageService.getUserName(),
      roles: storageService.getRoles(),
    );
  }

  Future<void> logout() async {
    try {
      await onBeforeSignOut?.call();
    } catch (_) {}
    apiService.clearAuthToken();
    await storageService.clearAll();
  }

  Future<bool> isLoggedIn() async => storageService.hasToken;
}
