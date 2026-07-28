import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'constants.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FcmService._showLocalNotification(message);
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'diwan_teacher_channel';
  static const _channelName = 'Teacher Alerts';
  static const _channelDesc = 'Real-time alerts from school — student submissions, timetable changes, announcements.';

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

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

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    await _registerToken();
    _messaging.onTokenRefresh.listen((_) => _registerToken());
  }

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

  static Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('fcm_token_teacher');
      if (stored == token) return;

      await prefs.setString('fcm_token_teacher', token);

      final userJson = prefs.getString(AppConstants.userKey);
      if (userJson == null) return;

      await ApiClient.instance.updateRecord(
        'users',
        _extractUid(userJson),
        {'fcmToken': token, 'fcmPlatform': Platform.isIOS ? 'ios' : 'android'},
      );
    } catch (_) {}
  }

  static String _extractUid(String userJson) {
    final match = RegExp(r'"(uid|id)"\s*:\s*"([^"]+)"').firstMatch(userJson);
    return match?.group(2) ?? '';
  }

  static Future<void> onLogin() => _registerToken();

  static Future<void> onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token_teacher');
    await _messaging.deleteToken();
  }
}
