import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_diwan_student/core/server_config.dart';
import 'constants.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  // Set this to AuthNotifier.logout so a 401 clears the in-memory auth state.
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
          // Notify the auth notifier first (clears in-memory state → triggers
          // router redirect to login). Storage cleanup happens inside logout().
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

  // Authenticated in-app password change. Throws a DioException on failure so
  // the caller can surface the server's real message (e.g. wrong current
  // password) — no fake success. Backend re-verifies currentPassword.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      AppConstants.changePasswordEndpoint,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  // ── Payments (PayTabs) ──────────────────────────────────────────────────────
  // Returns true only when the server reports a configured gateway. Used to
  // decide whether "Pay Now" can start a real checkout or must show an honest
  // "not available" message. Never assumes configured on error.
  Future<bool> isPaymentGatewayConfigured() async {
    try {
      final res = await _dio.get(AppConstants.paymentStatusEndpoint);
      final data = res.data;
      if (data is Map) return data['configured'] == true;
      return false;
    } catch (_) {
      return false;
    }
  }

  // Creates a real PayTabs hosted-payment session and returns the redirect URL
  // the app should open for the parent to complete payment. Throws on failure
  // so the caller surfaces the server's real error (e.g. gateway not configured).
  Future<String> createPaymentSession({
    required double amount,
    required String currency,
    required String description,
    required String orderId,
    required String returnUrl,
    String? customerName,
    String? customerEmail,
  }) async {
    final res = await _dio.post(
      AppConstants.paymentSessionEndpoint,
      data: {
        'amount': amount,
        'currency': currency,
        'description': description,
        'orderId': orderId,
        'returnUrl': returnUrl,
        if (customerName != null) 'customerName': customerName,
        if (customerEmail != null) 'customerEmail': customerEmail,
      },
    );
    final data = res.data;
    final url = data is Map
        ? (data['redirect_url'] ?? data['redirectUrl'] ?? data['url'])?.toString()
        : null;
    if (url == null || url.isEmpty) {
      throw Exception('Payment session did not return a checkout URL.');
    }
    return url;
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

  // Hard-delete a record. Used to remove a PTM's shared calendar entry when the
  // parent cancels, so a cancelled meeting doesn't linger on the calendar. The
  // server's generic DELETE route authorizes a parent for non-admin entities
  // (calendar_events is one). Best-effort — callers ignore failure.
  Future<void> deleteRecord(String entity, String id) async {
    await _dio.delete('${AppConstants.dataEndpoint}/$entity/$id');
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<void> markNotificationRead(String id) async {
    await _dio.put('${AppConstants.dataEndpoint}/${AppConstants.notifications}/$id', data: {'read': true});
  }
}
