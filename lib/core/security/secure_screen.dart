import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Blocks screenshots and screen recording (Android FLAG_SECURE) while a
/// screen showing customer contact details is open. iOS has no API to block
/// screenshots; the app-switcher snapshot is covered by the privacy overlay
/// in `main.dart` instead.
class SecureScreen {
  SecureScreen._();

  static const MethodChannel _channel = MethodChannel('com.teniqs.reweu_business/secure_screen');
  static int _holders = 0;

  static Future<void> enable() async {
    _holders++;
    if (_holders == 1) await _set(true);
  }

  static Future<void> disable() async {
    if (_holders == 0) return;
    _holders--;
    if (_holders == 0) await _set(false);
  }

  static Future<void> _set(bool secure) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'secure': secure});
    } on PlatformException catch (e) {
      debugPrint('SecureScreen error: $e');
    } on MissingPluginException {
      // Not available in tests or on unsupported platforms.
    }
  }
}
