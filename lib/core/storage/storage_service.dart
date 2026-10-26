import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _legacyKeyToken = 'jwt_token';
  static const String _keyUserId = 'user_id';
  static const String _keyBusinessId = 'business_id';
  static const String _keyBranchId = 'branch_id';
  static const String _keyBiometricsEnabled = 'biometrics_enabled';
  static const String _keyRoles = 'user_roles';

  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences prefs;

  StorageService({
    FlutterSecureStorage? secureStorage,
    required this.prefs,
  }) : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
            );

  static Future<StorageService> init() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    return StorageService(prefs: sharedPrefs);
  }

  // Token management
  Future<void> saveToken(String token) async {
    await prefs.setString(_keyToken, token);
    try {
      await _secureStorage.write(key: _keyToken, value: token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    final prefToken = prefs.getString(_keyToken) ?? prefs.getString(_legacyKeyToken);
    if (prefToken != null && prefToken.isNotEmpty) {
      return prefToken;
    }
    try {
      final secure = await _secureStorage.read(key: _keyToken) ??
          await _secureStorage.read(key: _legacyKeyToken);
      if (secure != null && secure.isNotEmpty) {
        // Cache in SharedPreferences for rapid synchronous/fallback reads
        await prefs.setString(_keyToken, secure);
        return secure;
      }
    } catch (_) {}
    return null;
  }

  Future<void> deleteToken() async {
    await prefs.remove(_keyToken);
    await prefs.remove(_legacyKeyToken);
    try {
      await _secureStorage.delete(key: _keyToken);
      await _secureStorage.delete(key: _legacyKeyToken);
    } catch (_) {}
  }

  // User and Business context
  Future<void> saveUserContext({
    required int userId,
    int? businessId,
    int? branchId,
    String? userEmail,
    String? userName,
    List<String>? roles,
  }) async {
    await prefs.setInt(_keyUserId, userId);
    if (businessId != null) {
      await prefs.setInt(_keyBusinessId, businessId);
    } else {
      await prefs.remove(_keyBusinessId);
    }
    if (branchId != null) {
      await prefs.setInt(_keyBranchId, branchId);
    } else {
      await prefs.remove(_keyBranchId);
    }
    if (userEmail != null) {
      await prefs.setString(_keyUserEmail, userEmail);
    }
    if (userName != null) {
      await prefs.setString(_keyUserName, userName);
    }
    if (roles != null) {
      await prefs.setStringList(_keyRoles, roles);
    }
  }

  int? getUserId() => prefs.getInt(_keyUserId);
  int? getBusinessId() => prefs.getInt(_keyBusinessId);
  int? getBranchId() => prefs.getInt(_keyBranchId);
  String? getUserEmail() => prefs.getString(_keyUserEmail);
  String? getUserName() => prefs.getString(_keyUserName);
  List<String> getRoles() => prefs.getStringList(_keyRoles) ?? [];
  bool isSuperAdmin() => getRoles().contains('SUPER_ADMIN');

  // Biometrics preference
  Future<void> setBiometricsEnabled(bool enabled) async {
    await prefs.setBool(_keyBiometricsEnabled, enabled);
  }

  bool isBiometricsEnabled() => prefs.getBool(_keyBiometricsEnabled) ?? false;

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await prefs.clear();
  }
}
