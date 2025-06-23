import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wireguard_flutter/wireguard_flutter_platform_interface.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../services/tray_manager.dart';
import '../providers/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final logger = Logger();

class VpnProvider with ChangeNotifier {
  WireGuardFlutterInterface? wireguard;
  bool _isConnecting = false;
  bool _isConnected = false;
  final Completer<void> _initializationCompleter = Completer<void>();

  static const String tunnelName = 'vpn_app_tunnel';

  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;

  VpnProvider() {
    _initializeWireGuard();
  }

  Future<void> _initializeWireGuard() async {
    logger.i('Starting WireGuard initialization...');
    if (wireguard != null) {
      logger.i('WireGuard already initialized');
      _initializationCompleter.complete();
      return;
    }

    try {
      wireguard = WireGuardFlutter.instance;
      logger.i('Instance retrieved: $wireguard');

      await wireguard!.initialize(interfaceName: tunnelName);
      logger.i('WireGuard initialized with $tunnelName');

      await _clearTempFiles();

      _initializationCompleter.complete();
    } catch (e) {
      _initializationCompleter.completeError(e);
      logger.e('Error initializing WireGuard: $e');
      if (e.toString().contains('Permission')) {
        logger.e('Error: Run the app as Administrator on Windows.');
      } else if (e.toString().contains('WireGuard not installed')) {
        logger.e('Error: WireGuard client is not installed.');
      }
      rethrow;
    }
  }

  Future<void> _clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFiles = tempDir.listSync().where((file) => file.path.contains('wg_'));
      for (var file in tempFiles) {
        logger.i('Deleting temp file: ${file.path}');
        try {
          await file.delete();
        } catch (e) {
          logger.w('Failed to delete temp file ${file.path}: $e');
        }
      }
      logger.i('Temp files cleared successfully');
    } catch (e) {
      logger.e('Error clearing temp files: $e');
    }
  }

  Future<Map<String, dynamic>> _getVpnConfig(String baseUrl, String? token) async {
    if (token == null) throw Exception('Не авторизован');

    final response = await http.get(
      Uri.parse('$baseUrl/get-vpn-config'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Ошибка получения конфигурации: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _getTestVpnConfig() async {
    const String serverPublicKey = 'p5fE09SR1FzW+a81zbSmZjW0h528cNx7IRKN+w0ulxo='; 
    const String serverAddress = '95.214.10.8:51820';
    return {
      'serverAddress': serverAddress,
      'serverPublicKey': serverPublicKey,
    };
  }

  final bool _isTestMode = true;

  Future<void> connect() async {
    String? token;
    try {
      await _initializationCompleter.future;
    } catch (e) {
      logger.e('Initialization failed: $e');
      rethrow;
    }

    final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!authProvider.isAuthenticated || authProvider.vpnKey == null) {
      throw Exception('Не авторизован или отсутствует VPN-ключ');
    }
    token = authProvider.token;

    if (wireguard == null) {
      logger.w('WireGuard instance is null, reinitializing...');
      await _initializeWireGuard();
      if (wireguard == null) throw Exception('Failed to initialize WireGuard');
    }

    _isConnecting = true;
    notifyListeners();
    try {
      final stage = await wireguard!.stage();
      logger.i('Current VPN stage: $stage');
      if (stage == VpnStage.connected) {
        logger.i('Stopping existing VPN service...');
        await wireguard!.stopVpn();
        await Future.delayed(const Duration(seconds: 2));
      }

      await _clearTempFiles();

      final configData = _isTestMode
          ? await _getTestVpnConfig()
          : await _getVpnConfig(AuthProvider.baseUrl, token);

      final config = '''
      [Interface]
      PrivateKey = ${authProvider.vpnKey}
      Address = 10.0.0.2/32
      DNS = 8.8.8.8, 1.1.1.1
      MTU = 1280

      [Peer]
      PublicKey = ${configData['serverPublicKey']}
      Endpoint = ${configData['serverAddress']}
      AllowedIPs = 0.0.0.0/0
      ''';

      await wireguard!.startVpn(
        serverAddress: configData['serverAddress'],
        wgQuickConfig: config,
        providerBundleIdentifier: 'com.shamovgk.vpn_app',
      );
      _isConnected = true;
      logger.i('VPN connected with ${_isTestMode ? 'test' : 'real'} config');
    } catch (e) {
      _isConnected = false;
      logger.e('Connection error: $e');
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
      trayHandler.updateTrayIconAndMenu();
    }
  }

  Future<void> disconnect() async {
    if (wireguard == null) {
      logger.w('WireGuard not initialized, skipping disconnect');
      return;
    }

    _isConnecting = true;
    notifyListeners();
    try {
      await wireguard!.stopVpn();
      _isConnected = false;
      logger.i('VPN disconnected');
    } catch (e) {
      logger.e('Disconnect error: $e');
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
      trayHandler.updateTrayIconAndMenu(); 
    }
  }

  @override
  void dispose() {
    if (isConnected) {
      disconnect().then((_) {
        logger.i('VPN disconnected on provider dispose');
      }).catchError((e) {
        logger.e('Error disconnecting VPN on provider dispose: $e');
      });
    }
    super.dispose();
  }
}