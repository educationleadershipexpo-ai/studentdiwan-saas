import 'package:flutter/foundation.dart';

class Environment {
  // Configured to point to the local NestJS backend server running on port 3001.
  // When running inside Android Emulator, '10.0.2.2' maps back to the localhost machine.
  static String get baseApiUrl {
    const definedUrl = String.fromEnvironment('API_URL');
    if (definedUrl.isNotEmpty) return _withApiSuffix(definedUrl);
    return 'https://portal.studentdiwan.com/api';
  }

  // The Dart backend serves every route under `/api`. A launch override of
  // API_URL (e.g. --dart-define=API_URL=http://localhost:3001) that omits the
  // suffix would otherwise POST to /session/login and 404, so normalize it here.
  static String _withApiSuffix(String url) {
    final trimmed = url.replaceAll(RegExp(r'/+$'), '');
    return trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
  }

  static const String environmentName = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );
}
