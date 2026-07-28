import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'constants.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this is called.
  // Show a local notification for the background message.
  await FcmService._showLocalNotification(message);
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'diwan_parent_channel';
  static const _channelName = 'School Notifications';
  static const _channelDesc = 'Real-time alerts from school — attendance, exams, fees, messages.';

  /// Call once in main() after Firebase.initializeApp().
  static Future<void> init() async {
    // Register the background handler before anything else
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS / Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Initialize flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false, // already requested above
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(initSettings);

    // Foreground message: show local notification
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Register/refresh FCM token with backend
    await _registerToken();
    _messaging.onTokenRefresh.listen((_) => _registerToken());
  }

  /// Displays a local notification for the given [RemoteMessage].
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  /// Sends the device FCM token to the backend so the server can push
  /// targeted notifications to this parent's device.
  static Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('fcm_token');
      if (stored == token) return; // unchanged

      await prefs.setString('fcm_token', token);

      // Save to backend under the notifications entity.
      // The server stores per-user FCM tokens on the User record.
      final userJson = prefs.getString(AppConstants.userKey);
      if (userJson == null) return;

      await ApiClient.instance.updateRecord(
        'users',
        // parse uid from stored user JSON
        _extractUid(userJson),
        {'fcmToken': token, 'fcmPlatform': Platform.isIOS ? 'ios' : 'android'},
      );
    } catch (_) {
      // Token registration failure is non-fatal; the app still works.
    }
  }

  static String _extractUid(String userJson) {
    // Minimal JSON parse to avoid importing dart:convert here
    final match = RegExp(r'"(?:uid|id)"\s*:\s*"([^"]+)"').firstMatch(userJson);
    return match?.group(1) ?? '';
  }

  /// Call after login to (re-)register the token now that we have a user.
  static Future<void> onLogin() => _registerToken();

  /// Clears the stored token on logout.
  static Future<void> onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
    await _messaging.deleteToken();
  }
}
