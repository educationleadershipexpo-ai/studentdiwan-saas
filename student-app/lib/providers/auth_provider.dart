import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/models.dart';
import 'package:dio/dio.dart';

// ── User Role ─────────────────────────────────────────────────────────────────
enum AppRole { student, teacher, parent, admin, unknown }

AppRole _parseRole(String raw) {
  switch (raw.toLowerCase()) {
    case 'student': return AppRole.student;
    case 'teacher':
    case 'class_teacher':
    case 'subject_teacher':
    case 'coordinator':
    case 'hod':
    case 'head_of_department':
    case 'headteacher':
    case 'head_teacher':
    case 'staff': return AppRole.teacher;
    case 'parent':
    case 'guardian': return AppRole.parent;
    case 'admin':
    case 'principal':
    case 'vice_principal': return AppRole.admin;
    default: return AppRole.unknown;
  }
}

// ── Auth State ────────────────────────────────────────────────────────────────
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isInitializing;
  final String? error;
  final UserProfile? user;
  final String? token;
  final AppRole role;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isInitializing = true,
    this.error,
    this.user,
    this.token,
    this.role = AppRole.unknown,
  });

  bool get isStudent  => role == AppRole.student;
  bool get isTeacher  => role == AppRole.teacher;
  bool get isParent   => role == AppRole.parent;
  bool get isAdmin    => role == AppRole.admin;

  // Backward compat (screens still reference .user?.displayName etc.)
  StudentProfile? get studentUser => isStudent || isAdmin ? _toStudentProfile() : null;

  StudentProfile? _toStudentProfile() {
    if (user == null) return null;
    return StudentProfile(
      id: user!.uid,
      displayName: user!.displayName,
      email: user!.email,
      gradeName: user!.gradeName,
      rollNumber: user!.rollNumber,
      avatarUrl: '',
    );
  }

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isInitializing,
    String? error,
    UserProfile? user,
    String? token,
    AppRole? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
      user: user ?? this.user,
      token: token ?? this.token,
      role: role ?? this.role,
    );
  }
}

// ── Universal User Profile (all roles) ────────────────────────────────────────
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String rawRole;
  final String gradeName;
  final String rollNumber;
  final String phone;
  final bool emailNotif;
  final bool smsNotif;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.rawRole,
    this.gradeName = '',
    this.rollNumber = '',
    this.phone = '',
    this.emailNotif = true,
    this.smsNotif = false,
  });

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (displayName.length >= 2) return displayName.substring(0, 2).toUpperCase();
    return '?';
  }

  factory UserProfile.fromJson(Map<String, dynamic> u) => UserProfile(
    uid: u['uid']?.toString() ?? u['id']?.toString() ?? '',
    email: u['email']?.toString() ?? '',
    displayName: u['displayName']?.toString() ?? u['name']?.toString() ?? 'User',
    rawRole: u['role']?.toString() ?? '',
    gradeName: u['gradeName']?.toString() ?? u['grade']?.toString() ?? '',
    rollNumber: u['rollNumber']?.toString() ?? '',
    phone: u['phone']?.toString() ?? '',
    emailNotif: u['emailNotif'] is bool ? u['emailNotif'] as bool : true,
    smsNotif: u['smsNotif'] is bool ? u['smsNotif'] as bool : false,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid, 'email': email, 'displayName': displayName,
    'role': rawRole, 'gradeName': gradeName, 'rollNumber': rollNumber,
    'phone': phone, 'emailNotif': emailNotif, 'smsNotif': smsNotif,
  };
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  late ApiClient _client;

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _client = ApiClient(prefs);
    _client.onUnauthorized = logout;
    await _restoreSession(prefs);
  }

  Future<void> _restoreSession(SharedPreferences prefs) async {
    try {
      final token = prefs.getString(StorageKeys.authToken);
      final userJson = prefs.getString(StorageKeys.userJson);
      if (token != null && userJson != null) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserProfile.fromJson(map);
        final role = _parseRole(user.rawRole);
        state = AuthState(isAuthenticated: true, isInitializing: false, user: user, token: token, role: role);
        return;
      }
      state = const AuthState(isAuthenticated: false, isInitializing: false);
    } catch (_) {
      state = const AuthState(isAuthenticated: false, isInitializing: false);
    }
  }

  // ── Login (accepts ALL roles) ──────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _client.post(
        '/session/login',
        data: {'email': email, 'password': password},
      );
      final body = response.data as Map<String, dynamic>;
      final token = body['token']?.toString();
      final userData = body['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        state = state.copyWith(isLoading: false, error: 'Invalid response from server.');
        return false;
      }

      final user = UserProfile.fromJson(userData);
      final role = _parseRole(user.rawRole);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.authToken, token);
      await prefs.setString(StorageKeys.userJson, jsonEncode(userData));
      await prefs.setString(StorageKeys.savedEmail, email);

      state = AuthState(isAuthenticated: true, isInitializing: false, user: user, token: token, role: role);
      return true;
    } on DioException catch (e) {
      final serverMsg = (e.response?.data as Map?)?.containsKey('error') == true
          ? (e.response!.data as Map)['error'].toString() : null;
      final msg = serverMsg ?? (e.type == DioExceptionType.connectionError
          ? 'Cannot connect to server. Make sure the server is running.'
          : e.message ?? 'Login failed. Please try again.');
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error: $e');
      return false;
    }
  }

  /// POST /api/session/forgot-password — the backend always replies
  /// generically (it never reveals whether the email exists). Returns an
  /// error message, or null on success.
  Future<String?> forgotPassword(String email) async {
    try {
      await _client.post('/session/forgot-password', data: {'email': email});
      return null;
    } on DioException catch (e) {
      return e.type == DioExceptionType.connectionError
          ? 'Cannot connect to server.'
          : 'Could not send reset request. Please try again.';
    } catch (_) {
      return 'Could not send reset request. Please try again.';
    }
  }

  Future<void> logout() async {
    state = const AuthState(isInitializing: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.authToken);
      await prefs.remove(StorageKeys.userJson);
    } catch (_) {}
  }

  // Persist a profile edit to the backend `users` row and update local session.
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

    await _client.put('/data/users/${current.uid}', data: body);

    final updated = UserProfile(
      uid: current.uid,
      email: current.email,
      displayName: body['displayName']?.toString() ?? current.displayName,
      rawRole: current.rawRole,
      gradeName: current.gradeName,
      rollNumber: current.rollNumber,
      phone: body['phone']?.toString() ?? current.phone,
      emailNotif: current.emailNotif,
      smsNotif: current.smsNotif,
    );
    state = state.copyWith(user: updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(StorageKeys.userJson);
      final map = raw != null ? jsonDecode(raw) as Map<String, dynamic> : <String, dynamic>{};
      map.addAll(body);
      map['displayName'] = updated.displayName;
      await prefs.setString(StorageKeys.userJson, jsonEncode(map));
    } catch (_) {}
  }

  // Persist notification-channel preferences to the backend `users` row and
  // update the local session. Real write — the toggles reflect the server state,
  // no fake success.
  Future<void> updateNotifPrefs({bool? emailNotif, bool? smsNotif}) async {
    final current = state.user;
    if (current == null) return;
    final body = <String, dynamic>{};
    if (emailNotif != null) body['emailNotif'] = emailNotif;
    if (smsNotif != null) body['smsNotif'] = smsNotif;
    if (body.isEmpty) return;

    await _client.put('/data/users/${current.uid}', data: body);

    final updated = UserProfile(
      uid: current.uid,
      email: current.email,
      displayName: current.displayName,
      rawRole: current.rawRole,
      gradeName: current.gradeName,
      rollNumber: current.rollNumber,
      phone: current.phone,
      emailNotif: emailNotif ?? current.emailNotif,
      smsNotif: smsNotif ?? current.smsNotif,
    );
    state = state.copyWith(user: updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(StorageKeys.userJson);
      final map = raw != null ? jsonDecode(raw) as Map<String, dynamic> : <String, dynamic>{};
      map.addAll(body);
      await prefs.setString(StorageKeys.userJson, jsonEncode(map));
    } catch (_) {}
  }

  // Real authenticated password change: POST /api/session/change-password with
  // the current + new password. Throws (DioException) on failure so the caller
  // surfaces the real server message — no fake success.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.post('/session/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
