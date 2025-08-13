// lib/features/vpn/providers/vpn_controller.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/errors/ui_error.dart';
import 'package:vpn_app/features/subscription/providers/subscription_providers.dart';
import 'package:vpn_app/features/vpn/platform/vpn_channel.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import '../usecases/connect_vpn_usecase.dart';
import '../usecases/disconnect_vpn_usecase.dart';
import '../usecases/is_connected_usecase.dart';

sealed class VpnState { const VpnState(); }
class VpnIdle extends VpnState { const VpnIdle(); }
class VpnConnecting extends VpnState { const VpnConnecting(); }
class VpnConnected extends VpnState { const VpnConnected(); }
class VpnDisconnecting extends VpnState { const VpnDisconnecting(); }
class VpnError extends VpnState {
  final String message;
  const VpnError(this.message);
}

final vpnControllerProvider =
  StateNotifierProvider<VpnController, VpnState>((ref) {
    final ctrl = VpnController(
      connect: ref.watch(connectVpnUseCaseProvider),
      disconnect: ref.watch(disconnectVpnUseCaseProvider),
      isConnected: ref.watch(isVpnConnectedUseCaseProvider),
      ref: ref,
    );
    return ctrl;
  }, name: 'vpnController');

class VpnController extends StateNotifier<VpnState> {
  VpnController({
    required this.connect,
    required this.disconnect,
    required this.isConnected,
    required this.ref,
  }) : super(const VpnIdle()){
    unawaited(bootstrap());

    ref.listen<bool>(vpnAccessProvider, (prev, next) async {
      if (prev == true && next == false && state is VpnConnected) {
        await disconnectPressed();
      }
    });

    _vpnSub = VpnChannel()
        .onStatus
        .distinct((a, b) => a.stage == b.stage)
        .listen(_onVpnStatus);

    ref.onDispose(() => _vpnSub?.cancel());
  }

  final ConnectVpn connect;
  final DisconnectVpn disconnect;
  final IsVpnConnected isConnected;
  final Ref ref;
  StreamSubscription<VpnStatusEvent>? _vpnSub;

  Future<void> bootstrap() async {
    try {
      final c = await isConnected();
      state = c ? const VpnConnected() : const VpnIdle();
    } catch (_) {
    }
  }

  bool get _canUseVpn => ref.read(vpnAccessProvider);

  void _onVpnStatus(VpnStatusEvent e) async {
    if (!_canUseVpn && e.stage == VpnStage.connected) {
      unawaited(disconnect());
      return;
    }

    if (e.stage == VpnStage.connected) {
      if (state is! VpnConnected) state = const VpnConnected();
    } else {
      if (state is VpnConnecting) {
        state = VpnError(e.reason ?? 'Не удалось подключиться');
      } else if (state is! VpnIdle) {
        state = const VpnIdle();
      }
    }
  }

  Future<void> connectPressed() async {
    if (state is VpnConnecting || state is VpnDisconnecting) return;
    if (!_canUseVpn) {
      state = const VpnError('Подписка не активна');
      return;
    }
    state = const VpnConnecting();
    try {
      await connect();
    } catch (e) {
      state = VpnError(presentableError(e));
    }
  }

  Future<void> disconnectPressed() async {
    if (state is VpnDisconnecting) return;
    state = const VpnDisconnecting();
    try {
      await disconnect();
    } catch (e) {
      state = VpnError(presentableError(e));
    }
  }
}
