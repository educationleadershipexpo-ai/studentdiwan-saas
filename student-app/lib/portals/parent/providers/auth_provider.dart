import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/models.dart';

// ── Auth State ────────────────────────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.token, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null && token != null;

  AuthState copyWith({UserModel? user, String? token, bool? isLoading, String? error}) => AuthState(
    user: user ?? this.user,
    token: token ?? this.token,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    // Wire the 401 handler so an expired token triggers immediate logout.
    ApiClient.instance.onUnauthorized = logout;
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    await loadFromStorage();
  }

  /// Public variant used by biometric login to re-hydrate state and return success/failure.
  Future<bool> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final userJson = prefs.getString(AppConstants.userKey);
    if (token != null && userJson != null) {
      try {
        final user = UserModel.fromJson(jsonDecode(userJson));
        state = AuthState(user: user, token: token);
        return true;
      } catch (_) {}
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.login(email, password);
      final token = response['token']?.toString();
      final userData = response['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        state = state.copyWith(isLoading: false, error: 'Invalid response from server.');
        return false;
      }

      final user = UserModel.fromJson(userData);

      if (user.role != 'parent' && user.role != 'guardian') {
        state = state.copyWith(isLoading: false, error: 'This app is for parents only. Please use the web portal.');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
      await prefs.setString(AppConstants.userKey, jsonEncode(userData));

      state = AuthState(user: user, token: token);
      return true;
    } on Exception catch (e) {
      final msg = e.toString().contains('SocketException')
          ? 'Cannot connect to server. Check your network.'
          : e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  // Persist edits to the parent's own profile. The server restricts a non-admin
  // self-write to USER_SELF_WRITABLE_FIELDS (displayName/name/phone/…), so we
  // only send those; anything else would be silently stripped. Updates in-memory
  // state and the cached user JSON so the whole app reflects the change at once.
  Future<void> updateProfile({String? displayName, String? phone}) async {
    final current = state.user;
    if (current == null) return;

    final body = <String, dynamic>{};
    if (displayName != null && displayName.trim().isNotEmpty) {
      body['displayName'] = displayName.trim();
      body['name'] = displayName.trim();
    }
    if (phone != null) body['phone'] = phone.trim();
    if (body.isEmpty) return;

    await ApiClient.instance.updateRecord('users', current.uid, body);

    final updated = current.copyWith(
      displayName: body['displayName']?.toString(),
      phone: body.containsKey('phone') ? body['phone']?.toString() : null,
    );
    state = state.copyWith(user: updated);
    await _persistUserPatch(body);
  }

  // Persist notification-channel preferences (emailNotif / smsNotif — both in
  // the server's self-writable allowlist). Real DB write, no local-only toggle.
  Future<void> updateNotifPrefs({bool? emailNotif, bool? smsNotif}) async {
    final current = state.user;
    if (current == null) return;

    final body = <String, dynamic>{};
    if (emailNotif != null) body['emailNotif'] = emailNotif;
    if (smsNotif != null) body['smsNotif'] = smsNotif;
    if (body.isEmpty) return;

    await ApiClient.instance.updateRecord('users', current.uid, body);

    final updated = current.copyWith(emailNotif: emailNotif, smsNotif: smsNotif);
    state = state.copyWith(user: updated);
    await _persistUserPatch(body);
  }

  // Merge a field patch into the cached user_json so a cold start rehydrates
  // the updated values (login writes the same key).
  Future<void> _persistUserPatch(Map<String, dynamic> patch) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.userKey);
      final map = raw != null
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : <String, dynamic>{};
      map.addAll(patch);
      await prefs.setString(AppConstants.userKey, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> logout() async {
    // Clear state first — triggers the router redirect immediately,
    // so the user sees the login screen without waiting for storage ops.
    state = const AuthState();
    // Clean up storage in the background; errors here are non-fatal.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userKey);
      await prefs.remove(AppConstants.selectedChildKey);
    } catch (_) {}
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
