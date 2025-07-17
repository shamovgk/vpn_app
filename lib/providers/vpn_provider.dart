import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wireguard_flutter/wireguard_flutter_platform_interface.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import '../services/tray_manager.dart';
import '../models/vpn_config.dart';

final logger = Logger();

class VpnProvider with ChangeNotifier {
  WireGuardFlutterInterface? _wireguard;
  bool _isConnecting = false;
  bool _isConnected = false;
  final Completer<void> _initializationCompleter = Completer<void>();
  static const String _tunnelName = 'vpn_app_tunnel';

  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  WireGuardFlutterInterface? get wireguard => _wireguard;

  VpnProvider() {
    _initializeWireGuard();
  }

  Future<void> _initializeWireGuard() async {
    logger.i('Starting WireGuard initialization...');
    if (_wireguard != null) {
      logger.i('WireGuard already initialized');
      if (!_initializationCompleter.isCompleted) _initializationCompleter.complete();
      return;
    }
    try {
      _wireguard = WireGuardFlutter.instance;
      await _wireguard!.initialize(interfaceName: _tunnelName);
      await _clearTempFiles();
      if (!_initializationCompleter.isCompleted) _initializationCompleter.complete();
      logger.i('WireGuard initialized successfully');
    } catch (e) {
      if (!_initializationCompleter.isCompleted) _initializationCompleter.completeError(e);
      logger.e('Error initializing WireGuard: $e');
      rethrow;
    }
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

  Future<VpnConfig> _fetchVpnConfig(String baseUrl, String token) async {
    logger.i('Запрос WireGuard-конфига');
    final response = await http.get(
      Uri.parse('$baseUrl/vpn/get-vpn-config'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final config = jsonDecode(response.body);
      return VpnConfig.fromJson(config);
    } else {
      throw Exception('Ошибка получения WireGuard-конфига: ${response.body}');
    }
  }

  String _buildConfig(VpnConfig config) {
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
    required String baseUrl,
    required String token,
    required bool isPaid,
    required String? trialEndDate,
    required int deviceCount,
    required int subscriptionLevel,
  }) async {
    await _initializationCompleter.future;
    final int maxDevices = subscriptionLevel == 1 ? 6 : 3;
    if (deviceCount > maxDevices) {
      throw Exception('Достигнут лимит устройств: $deviceCount/$maxDevices');
    }
    if (trialEndDate != null) {
      final trialEnd = DateTime.tryParse(trialEndDate);
      if (!isPaid && trialEnd != null && trialEnd.isBefore(DateTime.now())) {
        throw Exception('Срок действия пробного периода истёк');
      }
    } else if (!isPaid) {
      throw Exception('Подключение заблокировано: требуется оплата подписки');
    }
    if (_wireguard == null) {
      await _initializeWireGuard();
      if (_wireguard == null) throw Exception('Не удалось инициализировать WireGuard');
    }
    _isConnecting = true;
    notifyListeners();
    try {
      final stage = await _wireguard!.stage();
      if (stage == VpnStage.connected) {
        await _wireguard!.stopVpn();
        await Future.delayed(const Duration(seconds: 2));
      }
      await _clearTempFiles();
      final configData = await _fetchVpnConfig(baseUrl, token);
      final configText = _buildConfig(configData);

      await _wireguard!.startVpn(
        serverAddress: configData.endpoint,
        wgQuickConfig: configText,
        providerBundleIdentifier: 'com.shamovgk.vpn_app',
      );
      _isConnected = true;
      logger.i('VPN подключен');
    } catch (e) {
      _isConnected = false;
      logger.e('Ошибка подключения VPN: $e');
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        trayHandler.updateTrayIconAndMenu();
      }
    }
  }

  Future<void> disconnect() async {
    if (_wireguard == null) return;
    _isConnecting = true;
    notifyListeners();
    try {
      await _wireguard!.stopVpn();
      _isConnected = false;
      logger.i('VPN отключён');
    } catch (e) {
      logger.e('Ошибка при отключении: $e');
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        trayHandler.updateTrayIconAndMenu();
      }
    }
  }

  bool isConnectionAllowed({
    required bool isPaid,
    required String? trialEndDate,
    required int deviceCount,
    required int subscriptionLevel,
  }) {
    final int maxDevices = subscriptionLevel == 1 ? 6 : 3;
    if (trialEndDate != null) {
      final trialEnd = DateTime.tryParse(trialEndDate);
      return isPaid || (!isPaid && trialEnd != null && trialEnd.isAfter(DateTime.now()));
    }
    return isPaid && deviceCount < maxDevices;
  }

  @override
  void dispose() {
    if (_isConnected) {
      disconnect().then((_) {
        logger.i('VPN disconnected on provider dispose');
      }).catchError((e) {
        logger.e('Error disconnecting VPN on provider dispose: $e');
      });
    }
    super.dispose();
  }
}
