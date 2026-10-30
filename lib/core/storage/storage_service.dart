import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists session and preference data.
///
/// The auth token and any cached incident data (which contains customer
/// contact details) live only in the platform keystore/keychain via
/// [FlutterSecureStorage]. Non-sensitive preferences use SharedPreferences.
class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _legacyKeyToken = 'jwt_token';
  static const String _keyUserId = 'user_id';
  static const String _keyBusinessId = 'business_id';
  static const String _keyBranchId = 'branch_id';
  static const String _keyBiometricsEnabled = 'biometrics_enabled';
  static const String _keyBiometricsPrompted = 'biometrics_prompted';
  static const String _keyRoles = 'user_roles';
  static const String _keyPushToken = 'push_token';
  static const String _cachePrefix = 'cache_';

  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences prefs;
  String? _token;

  StorageService({
    FlutterSecureStorage? secureStorage,
    required this.prefs,
  }) : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static Future<StorageService> init({FlutterSecureStorage? secureStorage}) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs: sharedPrefs, secureStorage: secureStorage);
    await service._loadToken();
    return service;
  }

  Future<void> _loadToken() async {
    // Earlier builds also kept the token in SharedPreferences. Move it into
    // secure storage and remove the plaintext copy.
    final legacy = prefs.getString(_keyToken) ?? prefs.getString(_legacyKeyToken);
    if (legacy != null && legacy.isNotEmpty) {
      await _writeSecure(_keyToken, legacy);
      await prefs.remove(_keyToken);
      await prefs.remove(_legacyKeyToken);
    }
    _token = await _readSecure(_keyToken) ?? await _readSecure(_legacyKeyToken);
    if (_token != null && _token!.isEmpty) _token = null;
  }

  // Token management
  Future<void> saveToken(String token) async {
    _token = token;
    await _writeSecure(_keyToken, token);
  }

  /// The current token, held in memory after [init] so routing can check the
  /// session synchronously.
  String? get token => _token;

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<String?> getToken() async => _token;

  Future<void> deleteToken() async {
    _token = null;
    await _deleteSecure(_keyToken);
    await _deleteSecure(_legacyKeyToken);
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

  Future<void> saveBranchId(int? branchId) async {
    if (branchId != null) {
      await prefs.setInt(_keyBranchId, branchId);
    } else {
      await prefs.remove(_keyBranchId);
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
    await prefs.setBool(_keyBiometricsPrompted, true);
  }

  bool isBiometricsEnabled() => prefs.getBool(_keyBiometricsEnabled) ?? false;

  /// Whether the user has already been asked to turn on biometric unlock.
  bool wasBiometricsPrompted() => prefs.getBool(_keyBiometricsPrompted) ?? false;

  Future<void> markBiometricsPrompted() async {
    await prefs.setBool(_keyBiometricsPrompted, true);
  }

  // Push token registered with the backend for this install
  Future<void> savePushToken(String? token) async {
    if (token == null) {
      await prefs.remove(_keyPushToken);
    } else {
      await prefs.setString(_keyPushToken, token);
    }
  }

  String? getPushToken() => prefs.getString(_keyPushToken);

  // Offline cache (encrypted, cleared on sign out)
  Future<void> writeCache(String key, Object json) async {
    await _writeSecure('$_cachePrefix$key', jsonEncode(json));
  }

  Future<dynamic> readCache(String key) async {
    final raw = await _readSecure('$_cachePrefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    _token = null;
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
    // Keep the language choice (stored by easy_localization) across sign-ins.
    for (final key in prefs.getKeys().toList()) {
      if (key != 'locale') await prefs.remove(key);
    }
  }

  Future<String?> _readSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<void> _deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {}
  }
}
