// lib/core/cache/disk_cache.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DiskCache {
  static const String _ns = 'dc:'; // namespace
  static String _k(String key) => '$_ns$key';

  /// Сохранить JSON-совместимые данные под ключ с текущим временем.
  static Future<void> putJson(String key, Object? jsonEncodable) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = json.encode({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'data': jsonEncodable,
    });
    await prefs.setString(_k(key), payload);
  }

  /// Получить JSON по ключу, если не протух по TTL. Иначе — null.
  static Future<T?> getJson<T>(String key, {required Duration ttl, T Function(Object? raw)? cast}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_k(key));
    if (raw == null) return null;
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      final ts = DateTime.fromMillisecondsSinceEpoch(map['ts'] as int);
      final isFresh = DateTime.now().difference(ts) <= ttl;
      if (!isFresh) return null;
      final data = map['data'];
      if (cast != null) return cast(data);
      return data as T?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_k(key));
  }
}
