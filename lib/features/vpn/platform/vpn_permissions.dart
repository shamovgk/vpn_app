// lib/features/vpn/platform/vpn_permissions.dart
// Запрос/подготовка разрешений на Android (VpnService.prepare()), no-op на других платформах.
// В текущей реализации wireguard_flutter сам триггерит системный диалог при startVpn(),
// но хелпер оставляем, чтобы централизовать поток.

import 'dart:io' show Platform;

Future<bool> ensureVpnPermission() async {
  if (!Platform.isAndroid) return true;
  // Для текущего стека отдельный prepare не требуется — вернём true.
  // Если добавите нативный prepare через MethodChannel — дерните его отсюда.
  return true;
}
