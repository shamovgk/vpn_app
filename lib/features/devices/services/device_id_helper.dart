import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

final _storage = const FlutterSecureStorage();
const _deviceTokenKey = 'device_token';

Future<String> getDeviceToken() async {
  final plugin = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final android = await plugin.androidInfo;
    return android.id;
  } else if (Platform.isIOS) {
    final ios = await plugin.iosInfo;
    return ios.identifierForVendor ?? await _fallback();
  } else if (Platform.isWindows) {
    final win = await plugin.windowsInfo;
    return win.deviceId;
  } else if (Platform.isMacOS) {
    final mac = await plugin.macOsInfo;
    return mac.systemGUID ?? await _fallback();
  } else {
    return await _fallback();
  }
}

Future<String> _fallback() async {
  var token = await _storage.read(key: _deviceTokenKey);
  if (token == null) {
    token = const Uuid().v4();
    await _storage.write(key: _deviceTokenKey, value: token);
  }
  return token;
}
