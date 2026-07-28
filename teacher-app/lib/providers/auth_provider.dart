import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/offline_cache.dart';
import '../models/models.dart';

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

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    ApiClient.instance.onUnauthorized = logout;
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    await loadFromStorage();
  }

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

      // Verify that this user has teacher/school-staff access.
      // Real roles from DB: class_teacher, subject_teacher, coordinator, etc.
      const teacherRoles = {
        'teacher', 'class_teacher', 'subject_teacher',
        'coordinator', 'vice_principal', 'principal',
        'staff', 'admin'
      };
      if (!teacherRoles.contains(user.role)) {
        state = state.copyWith(isLoading: false, error: 'This app is for teachers only. Access Denied.');
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

  Future<void> logout() async {
    state = const AuthState();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userKey);
      // Clear in-memory and offline data cache so next teacher starts fresh
      OfflineCache.clear();
    } catch (_) {}
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
