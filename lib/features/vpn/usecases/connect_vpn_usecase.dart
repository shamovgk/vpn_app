// lib/features/vpn/usecases/connect_vpn_usecase.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vpn_providers.dart';

typedef ConnectVpn = Future<void> Function();

final connectVpnUseCaseProvider = Provider<ConnectVpn>((ref) {
  final repo = ref.watch(vpnRepositoryProvider);
  return () => repo.connect();
});
