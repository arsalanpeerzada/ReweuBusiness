import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/api_constants.dart';
import '../network/api_service.dart';
import '../storage/storage_service.dart';

/// Background FCM entry point. Notification messages are displayed by the
/// OS while the app is in the background; initialising Firebase here keeps
/// data-only messages from failing.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

/// Initialises Firebase (push + Crashlytics) when the platform config files
/// are present. Without `google-services.json` / `GoogleService-Info.plist`
/// the app still runs, with push and crash reporting switched off.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool available = false;

  static Future<bool> init() async {
    try {
      await Firebase.initializeApp();
      available = true;
    } catch (e) {
      debugPrint('Firebase is not configured, push and crash reporting are off: $e');
      available = false;
      return false;
    }

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    return true;
  }
}

class PushService {
  final ApiService apiService;
  final StorageService storageService;

  /// Called when the user taps a notification about an incident.
  void Function(int incidentId)? onOpenIncident;

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _initialised = false;
  int? _pendingIncidentId;

  PushService({
    required this.apiService,
    required this.storageService,
    this.onOpenIncident,
  });

  bool get isAvailable => FirebaseBootstrap.available;

  Future<void> init() async {
    if (!isAvailable || _initialised) return;
    _initialised = true;

    final channel = AndroidNotificationChannel(
      AppConfig.incidentChannelId,
      'push.channel_name'.tr(),
      description: 'push.channel_description'.tr(),
      importance: Importance.max,
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final id = int.tryParse(response.payload ?? '');
        if (id != null) _open(id);
      },
    );

    // iOS presents foreground notifications itself with these options.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _messageSub = FirebaseMessaging.onMessage.listen(_showForeground);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final id = incidentIdFromData(message.data);
      if (id != null) _open(id);
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _pendingIncidentId = incidentIdFromData(initial.data);
    }
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _pendingIncidentId ??= int.tryParse(launch?.notificationResponse?.payload ?? '');
    }
  }

  /// Incident the app was launched from, if any. Returns it once.
  int? takePendingIncident() {
    final id = _pendingIncidentId;
    _pendingIncidentId = null;
    return id;
  }

  /// Registers this install with the backend so incident alerts reach it.
  Future<void> registerDevice() async {
    if (!isAvailable || !storageService.hasToken) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      if (Platform.isIOS) {
        // The FCM token needs the APNs token, which can arrive shortly after launch.
        var apns = await FirebaseMessaging.instance.getAPNSToken();
        for (var i = 0; apns == null && i < 3; i++) {
          await Future<void>.delayed(const Duration(seconds: 2));
          apns = await FirebaseMessaging.instance.getAPNSToken();
        }
        if (apns == null) return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _sendToken(token);
      _refreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        _sendToken(t).catchError((_) {});
      });
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  Future<void> _sendToken(String token) async {
    final info = await PackageInfo.fromPlatform();
    await apiService.registerDeviceToken(
      deviceToken: token,
      deviceName: '${AppConfig.appName} (${Platform.operatingSystem})',
      osType: Platform.isIOS ? 'ios' : 'android',
      osVersion: Platform.operatingSystemVersion,
      appVersion: '${info.version}+${info.buildNumber}',
    );
    await storageService.savePushToken(token);
  }

  /// Removes this install from the backend and drops the FCM token, so a
  /// signed-out device stops receiving customer incident alerts.
  Future<void> unregisterDevice() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    final token = storageService.getPushToken();
    if (token != null) {
      try {
        await apiService.unregisterDeviceToken(token);
      } catch (_) {}
    }
    if (isAvailable) {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}
    }
    await storageService.savePushToken(null);
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    // iOS shows its own banner (see setForegroundNotificationPresentationOptions).
    if (notification == null || !Platform.isAndroid) return;
    final incidentId = incidentIdFromData(message.data);
    await _local.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          AppConfig.incidentChannelId,
          'push.channel_name'.tr(),
          channelDescription: 'push.channel_description'.tr(),
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_notification',
        ),
      ),
      payload: incidentId?.toString(),
    );
  }

  void _open(int incidentId) {
    final handler = onOpenIncident;
    if (handler != null) {
      handler(incidentId);
    } else {
      _pendingIncidentId = incidentId;
    }
  }

  /// Reads the incident id from the backend push payload
  /// (`relatedEntityType=INCIDENT`, `relatedEntityId`, `actionUrl=/incidents/{id}`).
  static int? incidentIdFromData(Map<String, dynamic> data) {
    if (data['relatedEntityType']?.toString().toUpperCase() == 'INCIDENT') {
      final id = int.tryParse(data['relatedEntityId']?.toString() ?? '');
      if (id != null && id > 0) return id;
    }
    final match = RegExp(r'/incidents/(\d+)').firstMatch(data['actionUrl']?.toString() ?? '');
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  Future<void> dispose() async {
    await _refreshSub?.cancel();
    await _messageSub?.cancel();
    await _openedSub?.cancel();
  }
}
