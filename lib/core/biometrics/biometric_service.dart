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
      return canAuthenticateWithBiometrics || isDeviceSupported;
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
      return biometrics.contains(BiometricType.face) ||
          biometrics.contains(BiometricType.strong);
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({
    String reason = 'Scan your face to unlock Reweu Companion',
    String title = 'Face Scan Verification',
    bool biometricOnly = true,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: title,
            biometricHint: 'Look at the camera to scan your face',
            biometricNotRecognized: 'Face not recognized. Look directly at the camera.',
            biometricSuccess: 'Face verified successfully',
            cancelButton: 'Cancel',
            deviceCredentialsRequiredTitle: 'Device Credentials Required',
            deviceCredentialsSetupDescription:
                'Please set up face unlock in device settings.',
          ),
          const IOSAuthMessages(
            localizedFallbackTitle: 'Use Passcode',
          ),
        ],
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Face scan authentication error: $e');
      return false;
    }
  }
}
