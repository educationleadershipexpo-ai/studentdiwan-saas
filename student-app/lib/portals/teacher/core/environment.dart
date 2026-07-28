/// Compile-time environment configuration.
///
/// Build with:
///   flutter run  --dart-define=ENV=dev   --dart-define=API_URL=http://10.0.2.2:3001
///   flutter run  --dart-define=ENV=prod  --dart-define=API_URL=https://api.yourschool.com
///
import 'package:flutter/foundation.dart';

class Env {
  static const String name =
      String.fromEnvironment('ENV', defaultValue: 'dev');

  static String get apiUrl {
    const definedUrl = String.fromEnvironment('API_URL');
    if (definedUrl.isNotEmpty) return _stripApiSuffix(definedUrl);
    return kIsWeb ? 'http://localhost:3001' : 'http://10.0.2.2:3001';
  }

  // This module builds paths as '/api/...' (see AppConstants.loginEndpoint),
  // so the base URL must NOT already end in '/api'. The unified launch passes
  // API_URL=http://localhost:3001/api; strip the suffix to avoid '/api/api'.
  static String _stripApiSuffix(String url) {
    final trimmed = url.replaceAll(RegExp(r'/+$'), '');
    return trimmed.endsWith('/api') ? trimmed.substring(0, trimmed.length - 4) : trimmed;
  }

  static bool get isDev => name == 'dev';
  static bool get isProd => name == 'prod';
}
