// lib/features/vpn/usecases/is_connected_usecase.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vpn_providers.dart';

typedef IsVpnConnected = Future<bool> Function();

final isVpnConnectedUseCaseProvider = Provider<IsVpnConnected>((ref) {
  final repo = ref.watch(vpnRepositoryProvider);
  return () => repo.isConnected();
});
