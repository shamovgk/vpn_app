// lib/core/storage/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSecureStorage {
  static const _keyToken = 'token';
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String? token) async {
    if (token == null) {
      await _storage.delete(key: _keyToken);
    } else {
      await _storage.write(key: _keyToken, value: token);
    }
  }

  static Future<String?> readToken() => _storage.read(key: _keyToken);
  static Future<void> clearToken() => _storage.delete(key: _keyToken);
}
