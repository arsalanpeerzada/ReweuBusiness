import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reweu_business/core/push/push_service.dart';
import 'package:reweu_business/core/security/app_lock.dart';
import 'package:reweu_business/core/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StorageService', () {
    test('keeps the token out of SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final storage = await StorageService.init();

      await storage.saveToken('secret-token');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where((k) => k.contains('token')), isEmpty);
      expect(storage.token, 'secret-token');

      final reloaded = await StorageService.init();
      expect(reloaded.token, 'secret-token');
    });

    test('moves a legacy plaintext token into secure storage', () async {
      SharedPreferences.setMockInitialValues({'jwt_token': 'legacy'});
      FlutterSecureStorage.setMockInitialValues({});

      final storage = await StorageService.init();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('jwt_token'), isNull);
      expect(storage.token, 'legacy');
    });

    test('sign out clears session data but keeps the language choice', () async {
      SharedPreferences.setMockInitialValues({'locale': 'ur_PK'});
      FlutterSecureStorage.setMockInitialValues({});
      final storage = await StorageService.init();
      await storage.saveToken('t');
      await storage.saveUserContext(userId: 1, businessId: 2);
      await storage.writeCache('feed_2_all_OPEN', {'content': []});

      await storage.clearAll();

      expect(storage.hasToken, isFalse);
      expect(storage.getUserId(), isNull);
      expect(await storage.readCache('feed_2_all_OPEN'), isNull);
      expect(storage.prefs.getString('locale'), 'ur_PK');
    });
  });

  group('AppLockController', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'biometrics_enabled': true});
      FlutterSecureStorage.setMockInitialValues({});
      storage = await StorageService.init();
      await storage.saveToken('t');
    });

    test('locks after the background timeout', () async {
      final lock = AppLockController(storage, lockAfter: Duration.zero);
      lock.unlock();
      expect(lock.isLocked, isFalse);

      lock.onBackgrounded();
      lock.onResumed();

      expect(lock.isLocked, isTrue);
    });

    test('does not lock for a short trip to the background', () async {
      final lock = AppLockController(storage, lockAfter: const Duration(minutes: 5));
      lock.unlock();

      lock.onBackgrounded();
      lock.onResumed();

      expect(lock.isLocked, isFalse);
    });

    test('never locks when biometrics are off', () async {
      await storage.setBiometricsEnabled(false);
      final lock = AppLockController(storage, lockAfter: Duration.zero);

      lock.onBackgrounded();
      lock.onResumed();

      expect(lock.isLocked, isFalse);
    });
  });

  group('PushService.incidentIdFromData', () {
    test('reads the related incident id', () {
      expect(
        PushService.incidentIdFromData({'relatedEntityType': 'INCIDENT', 'relatedEntityId': '42'}),
        42,
      );
    });

    test('falls back to the action URL', () {
      expect(PushService.incidentIdFromData({'actionUrl': '/incidents/77'}), 77);
    });

    test('ignores other notification types', () {
      expect(
        PushService.incidentIdFromData({'relatedEntityType': 'REVIEW', 'relatedEntityId': '5'}),
        isNull,
      );
    });
  });
}
