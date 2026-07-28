import 'package:shared_preferences/shared_preferences.dart';
import 'environment.dart';

class ServerConfig {
  static const String key = 'custom_server_url';
  static SharedPreferences? _prefs;

  static void init(SharedPreferences prefs) {
    _prefs = prefs;
  }

  static String get baseUrl {
    final customUrl = _prefs?.getString(key);
    if (customUrl != null && customUrl.isNotEmpty) {
      // Ensure the custom URL ends with /api
      final trimmed = customUrl.replaceAll(RegExp(r'/+$'), '');
      return trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
    }
    return Environment.baseApiUrl;
  }

  static String get baseUrlWithoutApi {
    final base = baseUrl;
    return base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
  }

  static Future<void> setCustomUrl(String? url) async {
    if (_prefs == null) return;
    if (url == null || url.trim().isEmpty) {
      await _prefs!.remove(key);
    } else {
      String formattedUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
      if (formattedUrl.isNotEmpty) {
        if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
          formattedUrl = 'http://$formattedUrl';
        }
        await _prefs!.setString(key, formattedUrl);
      } else {
        await _prefs!.remove(key);
      }
    }
  }
}
