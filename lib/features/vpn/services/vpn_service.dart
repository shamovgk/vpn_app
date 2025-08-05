import 'dart:async';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:wireguard_flutter/wireguard_flutter_platform_interface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import '../../../core/api_service.dart';
import '../models/vpn_config.dart';

final logger = Logger();

class VpnService {
  WireGuardFlutterInterface? _wireguard;
  static const String _tunnelName = 'vpn_app_tunnel';
  Completer<void>? _initializationCompleter;

  VpnService() {
    _initializeWireGuard();
  }

  Future<void> _initializeWireGuard() async {
    if (_wireguard != null) return;
    _initializationCompleter ??= Completer<void>();
    try {
      _wireguard = WireGuardFlutter.instance;
      await _wireguard!.initialize(interfaceName: _tunnelName);
      await _clearTempFiles();
      _initializationCompleter?.complete();
      logger.i('WireGuard initialized successfully');
    } catch (e) {
      _initializationCompleter?.completeError(e);
      logger.e('Error initializing WireGuard: $e');
      rethrow;
    }
  }

  Future<void> waitInitialized() async {
    await _initializationCompleter?.future;
  }

  Future<void> _clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFiles = tempDir.listSync().where((file) => file.path.contains('wg_'));
      for (var file in tempFiles) {
        try {
          await file.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<VpnConfig> fetchVpnConfig(ApiService apiService) async {
    final res = await apiService.get('/vpn/get-vpn-config', auth: true);
    return VpnConfig.fromJson(res);
  }

  String buildConfig(VpnConfig config) {
    return '''
    [Interface]
    PrivateKey = ${config.privateKey}
    Address = ${config.address}
    DNS = ${config.dns}
    
    [Peer]
    PublicKey = ${config.serverPublicKey}
    Endpoint = ${config.endpoint}
    AllowedIPs = ${config.allowedIps}
    ''';
  }

  Future<void> connect({
    required ApiService apiService,
    required bool isPaid,
    required String? trialEndDate,
  }) async {
    await _initializeWireGuard();
    if (trialEndDate != null) {
      final trialEnd = DateTime.tryParse(trialEndDate);
      if (!isPaid && trialEnd != null && trialEnd.isBefore(DateTime.now())) {
        throw Exception('Срок действия пробного периода истёк');
      }
    } else if (!isPaid) {
      throw Exception('Подключение заблокировано: требуется оплата подписки');
    }
    if (_wireguard == null) throw Exception('WireGuard не инициализирован');

    final stage = await _wireguard!.stage();
    if (stage == VpnStage.connected) {
      await _wireguard!.stopVpn();
      await Future.delayed(const Duration(seconds: 2));
    }
    await _clearTempFiles();
    final configData = await fetchVpnConfig(apiService);
    final configText = buildConfig(configData);

    await _wireguard!.startVpn(
      serverAddress: configData.endpoint,
      wgQuickConfig: configText,
      providerBundleIdentifier: 'com.shamovgk.vpn_app',
    );
  }

  Future<void> disconnect() async {
    if (_wireguard != null) {
      await _wireguard!.stopVpn();
    }
  }
}
