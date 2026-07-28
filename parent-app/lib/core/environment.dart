/// Compile-time environment configuration.
///
/// Build with:
///   flutter run  --dart-define=ENV=dev   --dart-define=API_URL=http://10.0.2.2:3001
///   flutter run  --dart-define=ENV=prod  --dart-define=API_URL=https://api.yourschool.com
///
/// Physical device (same Wi-Fi):
///   flutter run  --dart-define=API_URL=http://192.168.1.x:3001
import 'package:flutter/foundation.dart';

class Env {
  static const String name =
      String.fromEnvironment('ENV', defaultValue: 'dev');

  static String get apiUrl {
    const definedUrl = String.fromEnvironment('API_URL');
    if (definedUrl.isNotEmpty) return definedUrl;
    return 'https://portal.studentdiwan.com';
  }

  static bool get isDev => name == 'dev';
  static bool get isProd => name == 'prod';
}
