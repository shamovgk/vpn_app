// lib/features/vpn/usecases/disconnect_vpn_usecase.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vpn_providers.dart';

typedef DisconnectVpn = Future<void> Function();

final disconnectVpnUseCaseProvider = Provider<DisconnectVpn>((ref) {
  final repo = ref.watch(vpnRepositoryProvider);
  return () => repo.disconnect();
});
