// lib/features/vpn/platform/vpn_isolates.dart
// CPU-bound утилиты в изоляте: сборка wg-quick, валидация ключей/полей.
// Без внешних криптозависимостей: генерацию ключей оставляем на сервер/плагин.

import 'dart:isolate';
import 'package:vpn_app/features/vpn/models/vpn_config.dart';

String _buildWgQuickSync(VpnConfig c) => '''
[Interface]
PrivateKey = ${c.privateKey}
Address = ${c.address}
DNS = ${c.dns}

[Peer]
PublicKey = ${c.serverPublicKey}
Endpoint = ${c.endpoint}
AllowedIPs = ${c.allowedIps}
''';

Future<String> buildWgQuickIsolate(VpnConfig c) {
  return Isolate.run(() => _buildWgQuickSync(c));
}

void validateConfigSync(VpnConfig c) {
  void req(String name, String v) {
    if (v.trim().isEmpty) throw ArgumentError('$name is empty');
  }
  req('privateKey', c.privateKey);
  req('address', c.address);
  req('serverPublicKey', c.serverPublicKey);
  req('endpoint', c.endpoint);
  req('allowedIps', c.allowedIps);
}

Future<void> validateConfigIsolate(VpnConfig c) {
  return Isolate.run(() {
    validateConfigSync(c);
  });
}
