import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_diwan_student/core/server_config.dart';
import 'constants.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  VoidCallback? onUnauthorized;

  ApiClient._() {
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

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    // In local development, we call the standard login route
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

  // ── File Upload ───────────────────────────────────────────────────────────
  // Posts a base64 data URL to the server's /api/uploads endpoint and returns
  // the stored file URL (e.g. "/uploads/169...-report.pdf").
  Future<String> uploadFile(String name, String dataUrl) async {
    final response = await _dio.post('/api/uploads', data: {
      'name': name,
      'fileData': dataUrl,
    });
    final data = response.data as Map<String, dynamic>;
    return data['url']?.toString() ?? '';
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<void> markNotificationRead(String id) async {
    await _dio.put('${AppConstants.dataEndpoint}/${AppConstants.notifications}/$id', data: {'read': true});
  }
}
