import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vpn_app/main.dart';
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
    if (token == null) {
      logger.e('Token is null, authentication required');
      throw Exception('Authentication required');
    }

    logger.i('Requesting VPN config from $baseUrl/get-vpn-config with token: Bearer $token');
    final response = await http.get(
      Uri.parse('$baseUrl/get-vpn-config'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final config = jsonDecode(response.body);
      if (config is Map<String, dynamic> && 
          config.containsKey('clientPrivateKey') &&
          config.containsKey('serverPublicKey') &&
          config.containsKey('serverAddress') &&
          config.containsKey('clientIp')) {
        logger.i('Received config: $config');
        return config; // Добавлен clientIp
      } else {
        logger.e('Invalid configuration: missing required fields - $config');
        throw Exception('Invalid configuration: missing required fields');
      }
    } else {
      logger.e('Error fetching config: ${response.statusCode} - ${response.body}');
      throw Exception('Ошибка получения конфигурации: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _getTestVpnConfig() async {
    const String serverPublicKey = 'p5fE09SR1FzW+a81zbSmZjW0h528cNx7IRKN+w0ulxo=';
    const String serverAddress = '95.214.10.8:51820';
    return {
      'serverAddress': serverAddress,
      'serverPublicKey': serverPublicKey,
      'clientPrivateKey': 'тестовый_приватный_ключ',
      'clientIp': '10.0.0.2/32', // Тестовый IP
    };
  }

  final bool _isTestMode = false;

  Future<void> connect() async {
    try {
      await _initializationCompleter.future;
    } catch (e) {
      logger.e('Initialization failed: $e');
      rethrow;
    }

    final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      logger.e('Not authenticated or token missing: ${authProvider.token}');
      await authProvider.checkAuthStatus();
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        throw Exception('Не авторизован или отсутствует токен');
      }
    }

    // Проверка оплаты
    if (!authProvider.isPaid) {
      logger.w('Connection blocked: User has not paid for subscription');
      throw Exception('Подключение заблокировано: требуется оплата подписки');
    }

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
          : await _getVpnConfig(AuthProvider.baseUrl, authProvider.token);
      logger.i('Received config data: $configData');

      final config = '''
      [Interface]
      PrivateKey = ${configData['clientPrivateKey']}
      Address = ${configData['clientIp']}
      DNS = 8.8.8.8, 1.1.1.1
      MTU = 1280

      [Peer]
      PublicKey = ${configData['serverPublicKey']}
      Endpoint = ${configData['serverAddress']}
      AllowedIPs = 0.0.0.0/0
      ''';
      logger.i('Generated WireGuard config:\n$config');

      await wireguard!.startVpn(
        serverAddress: configData['serverAddress'],
        wgQuickConfig: config,
        providerBundleIdentifier: 'com.shamovgk.vpn_app',
      );
      _isConnected = true;
      logger.i('VPN connected with ${_isTestMode ? 'test' : 'real'} config');
    } catch (e) {
      _isConnected = false;
      logger.e('Connection error details: $e, Stack trace: ${StackTrace.current}');
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