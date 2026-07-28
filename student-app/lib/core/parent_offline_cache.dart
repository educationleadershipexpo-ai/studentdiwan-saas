import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Lightweight offline cache backed by Hive.
///
/// Usage:
///   await OfflineCache.init();           // call once in main()
///   await OfflineCache.put('key', data);
///   final data = OfflineCache.get('key');
class ParentOfflineCache {
  static const _boxName = 'api_cache';
  static const _ttlBoxName = 'api_cache_ttl';

  // Default TTL: 15 minutes for most data, 60 min for reference data.
  static const Duration defaultTtl = Duration(minutes: 15);

  static late Box<String> _box;
  static late Box<int> _ttlBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    _ttlBox = await Hive.openBox<int>(_ttlBoxName);
  }

  /// Stores a list of maps as JSON under [key].
  static Future<void> put(
    String key,
    List<Map<String, dynamic>> data, {
    Duration ttl = defaultTtl,
  }) async {
    await _box.put(key, jsonEncode(data));
    await _ttlBox.put(
      key,
      DateTime.now().add(ttl).millisecondsSinceEpoch,
    );
  }

  /// Returns cached data if it exists and hasn't expired, otherwise null.
  static List<Map<String, dynamic>>? get(String key) {
    final expiresAt = _ttlBox.get(key);
    if (expiresAt == null) return null;
    if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
      _box.delete(key);
      _ttlBox.delete(key);
      return null;
    }
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  /// Returns stale data (even if expired) — used as fallback when offline.
  static List<Map<String, dynamic>>? getStale(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  static Future<void> invalidate(String key) async {
    await _box.delete(key);
    await _ttlBox.delete(key);
  }

  static Future<void> clear() async {
    await _box.clear();
    await _ttlBox.clear();
  }

  static bool isStale(String key) {
    final expiresAt = _ttlBox.get(key);
    if (expiresAt == null) return true;
    return DateTime.now().millisecondsSinceEpoch > expiresAt;
  }
}
