import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  VoidCallback? onUnauthorized;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  /// Sync token from web app (for cross-platform session sharing)
  /// Call this when receiving a token from web via deep link or QR code
  Future<void> syncTokenFromWeb(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userKey, userData['uid'] ?? '');
    // Update dio headers for subsequent requests
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Get current token for sharing with web app
  Future<String?> getCurrentToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      AppConstants.loginEndpoint,
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post(
      AppConstants.forgotPasswordEndpoint,
      data: {'email': email},
    );
  }

  // ── Generic Data Fetch ────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAll(
    String entity, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.dataEndpoint}/$entity',
        queryParameters: params,
      );
      final data = response.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map) {
        final values = data['data'] ?? data['records'] ?? data['items'] ?? data['results'];
        if (values is List) return values.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('[ApiClient] Error fetching $entity: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getOne(String entity, String id) async {
    try {
      final response = await _dio.get('${AppConstants.dataEndpoint}/$entity/$id');
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return data.cast<String, dynamic>();
      return null;
    } catch (e) {
      debugPrint('[ApiClient] Error fetching single $entity ($id): $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createRecord(String entity, Map<String, dynamic> body) async {
    final response = await _dio.post('${AppConstants.dataEndpoint}/$entity', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRecord(
    String entity,
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put('${AppConstants.dataEndpoint}/$entity/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteRecord(String entity, String id) async {
    await _dio.delete('${AppConstants.dataEndpoint}/$entity/$id');
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<void> markNotificationRead(String id) async {
    await _dio.put('${AppConstants.dataEndpoint}/${AppConstants.notifications}/$id', data: {'read': true});
  }
}
