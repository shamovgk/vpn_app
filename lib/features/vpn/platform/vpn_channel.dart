// lib/features/vpn/platform/vpn_channel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:wireguard_flutter/wireguard_flutter_platform_interface.dart';

@immutable
class VpnStatusEvent {
  final VpnStage stage;
  final String? reason;
  final int? txBytes;
  final int? rxBytes;
  final DateTime ts;

  VpnStatusEvent({
    required this.stage,
    this.reason,
    this.txBytes,
    this.rxBytes,
    DateTime? ts,
  }) : ts = ts ?? DateTime.now();
}

class VpnChannel {
  VpnChannel._();
  static final VpnChannel _i = VpnChannel._();
  factory VpnChannel() => _i;

  WireGuardFlutterInterface? _wg;
  String _ifaceName = 'vpn_app_tunnel';
  Timer? _poller;
  final _controller = StreamController<VpnStatusEvent>.broadcast();
  Stream<VpnStatusEvent> get onStatus => _controller.stream;

  bool _initialized = false;

  Future<void> initialize({String interfaceName = 'vpn_app_tunnel'}) async {
    if (_initialized) return;
    _ifaceName = interfaceName;
    _wg = WireGuardFlutter.instance;
    await _wg!.initialize(interfaceName: _ifaceName);
    _initialized = true;
  }

  Future<VpnStage> stage() async {
    if (_wg == null) return VpnStage.disconnected;
    return _wg!.stage();
  }

  Future<void> start({
    required String wgQuickConfig,
    required String serverAddress,
    required String providerBundleIdentifier,
  }) async {
    await initialize(interfaceName: _ifaceName);
    final s = await stage();
    if (s == VpnStage.connected) {
      await _wg!.stopVpn();
      await Future.delayed(const Duration(seconds: 1));
    }

    await _wg!.startVpn(
      serverAddress: serverAddress,
      wgQuickConfig: wgQuickConfig,
      providerBundleIdentifier: providerBundleIdentifier,
    );

    _startPolling();
  }

  Future<void> stop() async {
    if (_wg == null) return;
    await _wg!.stopVpn();
    _emitOnce();
    _stopPolling();
  }

  void _startPolling() {
    _stopPolling();
    _poller = Timer.periodic(const Duration(milliseconds: 700), (_) async {
      await _emitOnce();
    });
  }

  void _stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  Future<void> _emitOnce() async {
    try {
      final s = await stage();
      _controller.add(VpnStatusEvent(stage: s));
      if (s == VpnStage.disconnected) {
        _stopPolling();
      }
    } catch (e) {
      _controller.add(VpnStatusEvent(stage: VpnStage.disconnected, reason: '$e'));
      _stopPolling();
    }
  }

  @visibleForTesting
  void dispose() {
    _stopPolling();
    _controller.close();
    _initialized = false;
    _wg = null;
  }
}

