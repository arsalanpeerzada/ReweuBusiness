import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint('Biometrics availability check error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Available biometrics query error: $e');
      return [];
    }
  }

  Future<bool> hasFaceBiometrics() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.face);
    } catch (_) {
      return false;
    }
  }

  /// Prompts for biometrics. With [biometricOnly] false the device passcode
  /// is accepted as a fallback, which the lock screen uses so a failed sensor
  /// never locks a manager out mid-incident.
  Future<bool> authenticate({
    String? reason,
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason ?? 'biometrics.reason_unlock'.tr(),
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'biometrics.title'.tr(),
            biometricHint: 'biometrics.hint'.tr(),
            biometricNotRecognized: 'biometrics.not_recognised'.tr(),
            biometricSuccess: 'biometrics.success'.tr(),
            cancelButton: 'common.cancel'.tr(),
            deviceCredentialsRequiredTitle: 'biometrics.credentials_required'.tr(),
            deviceCredentialsSetupDescription: 'biometrics.setup_description'.tr(),
          ),
          IOSAuthMessages(
            localizedFallbackTitle: 'biometrics.use_passcode'.tr(),
            cancelButton: 'common.cancel'.tr(),
          ),
        ],
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }
}
