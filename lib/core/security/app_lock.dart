import 'package:flutter/foundation.dart';

import '../config/api_constants.dart';
import '../storage/storage_service.dart';

/// Tracks whether biometric unlock is required before the app's content is
/// shown: on a cold start, and after the app has been in the background for
/// longer than [AppConfig.lockAfter].
class AppLockController extends ChangeNotifier {
  final StorageService storageService;
  final Duration lockAfter;
  bool _locked;
  DateTime? _backgroundedAt;

  AppLockController(this.storageService, {this.lockAfter = AppConfig.lockAfter})
      : _locked = storageService.hasToken && storageService.isBiometricsEnabled();

  bool get _lockApplies => storageService.hasToken && storageService.isBiometricsEnabled();

  bool get isLocked => _locked && _lockApplies;

  void onBackgrounded() {
    _backgroundedAt ??= DateTime.now();
  }

  void onResumed() {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since != null && _lockApplies && DateTime.now().difference(since) >= lockAfter) {
      _locked = true;
      notifyListeners();
    }
  }

  void unlock() {
    _locked = false;
    notifyListeners();
  }

  /// Clears the lock state, for example after signing in or out.
  void reset() {
    _locked = false;
    _backgroundedAt = null;
    notifyListeners();
  }
}
