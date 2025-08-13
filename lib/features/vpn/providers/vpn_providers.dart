// lib/features/vpn/providers/vpn_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import '../repositories/vpn_repository.dart';
import '../repositories/vpn_repository_impl.dart';

export 'vpn_controller.dart';

final vpnRepositoryProvider = Provider<VpnRepository>((ref) {
  return VpnRepositoryImpl(ref.read(apiServiceProvider));
}, name: 'vpnRepository');
