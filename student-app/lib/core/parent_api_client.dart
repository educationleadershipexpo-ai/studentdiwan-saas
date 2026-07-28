import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

import 'server_config.dart';

class ParentApiClient {
  static ParentApiClient? _instance;
  late final Dio _dio;

  // Set this to AuthNotifier.logout so a 401 clears the in-memory auth state.
  VoidCallback? onUnauthorized;

  ParentApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: ServerConfig.baseUrlWithoutApi,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.baseUrl = ServerConfig.baseUrlWithoutApi;
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Notify the auth notifier first (clears in-memory state → triggers
          // router redirect to login). Storage cleanup happens inside logout().
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  static ParentApiClient get instance {
    _instance ??= ParentApiClient._();
    return _instance!;
  }

  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.selectedChildKey);
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

  // ── Generic Data Fetch (with optional server-side filter params) ──────────
  Future<List<Map<String, dynamic>>> getAll(
    String entity, {
    Map<String, dynamic>? params,
  }) async {
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
  }

  Future<Map<String, dynamic>> createRecord(String entity, Map<String, dynamic> body) async {
    final response = await _dio.post('${AppConstants.dataEndpoint}/$entity', data: body);
    return response.data as Map<String, dynamic>;
  }

  // ── Single record by id ───────────────────────────────────────────────────
  // Returns the raw record map, or null if not found / not an object.
  Future<Map<String, dynamic>?> getOne(String entity, String id) async {
    final response = await _dio.get('${AppConstants.dataEndpoint}/$entity/$id');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return null;
  }

  Future<Map<String, dynamic>> updateRecord(
    String entity,
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put('${AppConstants.dataEndpoint}/$entity/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<void> markNotificationRead(String id) async {
    await _dio.put('${AppConstants.dataEndpoint}/${AppConstants.notifications}/$id', data: {'read': true});
  }
}
