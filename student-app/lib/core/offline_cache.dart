import 'package:hive_flutter/hive_flutter.dart';
import 'constants.dart';

class OfflineCache {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(CacheBoxes.offlineCache);
  }

  static Box get _box => Hive.box(CacheBoxes.offlineCache);

  static Future<void> set(String key, dynamic value) async {
    await _box.put(key, value);
  }

  static dynamic get(String key, {dynamic defaultValue}) {
    return _box.get(key, defaultValue: defaultValue);
  }

  static Future<void> remove(String key) async {
    await _box.delete(key);
  }

  static Future<void> clearAll() async {
    await _box.clear();
  }
}
