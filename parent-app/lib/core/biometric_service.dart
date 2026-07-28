import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  static const _enabledKey = 'biometric_enabled';

  /// Returns true if the device supports biometrics AND the user has enrolled.
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isDeviceSupported) return false;
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the user has opted in to biometric login.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Saves the user's biometric-login preference.
  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  /// Prompts the user to authenticate.
  /// Returns true on success, false on failure/cancel.
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access the Parent Portal',
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN/pattern fallback
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Returns the saved login credentials for biometric re-login.
  static Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('bio_email');
    final token = prefs.getString(AppConstants.tokenKey);
    if (email == null || token == null) return null;
    return {'email': email, 'token': token};
  }

  /// Saves credentials after a successful password login (so biometric can reuse them).
  static Future<void> saveCredentials(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bio_email', email);
  }

  /// Clears saved biometric credentials on logout.
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bio_email');
    await prefs.remove(_enabledKey);
  }
}
