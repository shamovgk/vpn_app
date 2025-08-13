// lib/core/platform/device_id.dart
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

const _kDeviceTokenKey = 'device_token';
const _storage = FlutterSecureStorage();

class DevicePlatformInfo {
  final String token; // стабильный токен (persisted)
  final String model; // человекочитаемая модель
  final String os;    // Android/iOS/Windows/macOS/Linux/Unknown
  const DevicePlatformInfo({required this.token, required this.model, required this.os});

  @override
  String toString() => 'DevicePlatformInfo(os=$os, model=$model, token=$token)';
}

class DeviceId {
  DeviceId._();

  /// Главная точка входа: стабильный токен + платф. инфо
  static Future<DevicePlatformInfo> getCurrentDeviceInfo() async {
    final token = await _getOrCreateStableToken();
    final (model, osName) = await _getPlatformModelAndOs();
    return DevicePlatformInfo(token: token, model: model, os: osName);
  }

  static Future<String> getDeviceToken() async => _getOrCreateStableToken();

  /// 1) читаем уже сохранённый токен
  /// 2) если нет — пытаемся сгенерить на основе platform IDs
  /// 3) если не получилось — генерим UUIDv4
  static Future<String> _getOrCreateStableToken() async {
    // Web не поддерживаем здесь
    if (kIsWeb) return _ensureStored(const Uuid().v4());

    final existing = await _storage.read(key: _kDeviceTokenKey);
    if (existing != null && existing.isNotEmpty) return existing;

    String? candidate;
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        candidate = a.id; // SSAID: приемлемо для app-scoped ID
      } else if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        candidate = i.identifierForVendor;
      } else if (Platform.isWindows) {
        final w = await plugin.windowsInfo;
        candidate = w.deviceId;
      } else if (Platform.isMacOS) {
        final m = await plugin.macOsInfo;
        candidate = m.systemGUID;
      } else if (Platform.isLinux) {
        final l = await plugin.linuxInfo;
        // machineId может быть null в некоторых окружениях
        candidate = l.machineId ?? l.variantId;
      }
    } catch (_) {
      // глушим — пойдём на UUID
    }

    return _ensureStored(candidate ?? const Uuid().v4());
  }

  static Future<String> _ensureStored(String value) async {
    await _storage.write(key: _kDeviceTokenKey, value: value);
    return value;
  }

  static Future<(String model, String osName)> _getPlatformModelAndOs() async {
    if (kIsWeb) return ('Web', 'Web');

    String model = 'Unknown';
    String osName = Platform.operatingSystem; // android/ios/windows/macos/linux

    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        model = a.model;
        osName = 'Android';
      } else if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        // utsname.machine (например, iPhone15,3) — оставим как есть
        model = i.utsname.machine;
        osName = 'iOS';
      } else if (Platform.isWindows) {
        final w = await plugin.windowsInfo;
        model = w.computerName;
        osName = 'Windows';
      } else if (Platform.isMacOS) {
        final m = await plugin.macOsInfo;
        model = m.model;
        osName = 'macOS';
      } else if (Platform.isLinux) {
        final l = await plugin.linuxInfo;
        model = l.prettyName;
        osName = 'Linux';
      }
    } catch (_) {
      // оставим дефолты
    }

    return (model, _normalizeOsName(osName));
  }

  static String _normalizeOsName(String raw) {
    switch (raw.toLowerCase()) {
      case 'android': return 'Android';
      case 'ios':     return 'iOS';
      case 'windows': return 'Windows';
      case 'macos':   return 'macOS';
      case 'linux':   return 'Linux';
      default:        return 'Unknown';
    }
  }
}
