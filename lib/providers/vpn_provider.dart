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
  WireGuardFlutterInterface? _wireguard;
  bool _isConnecting = false;
  bool _isConnected = false;
  final Completer<void> _initializationCompleter = Completer<void>();
  static const String _tunnelName = 'vpn_app_tunnel';

  // Геттеры
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  WireGuardFlutterInterface? get wireguard => _wireguard;

  VpnProvider() {
    _initializeWireGuard();
  }

  // Утилитарные методы
  Future<void> _initializeWireGuard() async {
    logger.i('Starting WireGuard initialization...');
    if (_wireguard != null) {
      logger.i('WireGuard already initialized');
      _initializationCompleter.complete();
      return;
    }

    try {
      _wireguard = WireGuardFlutter.instance;
      logger.i('Instance retrieved: $_wireguard');
      await _wireguard!.initialize(interfaceName: _tunnelName);
      logger.i('WireGuard initialized with $_tunnelName');
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

  Future<Map<String, dynamic>> _fetchVpnConfig(String baseUrl, String? token) async {
    if (token == null) {
      logger.e('Token is null, authentication required');
      throw Exception('Authentication required');
    }

    logger.i('Requesting VPN config from $baseUrl/get-vpn-config with token: Bearer $token');
    final response = await http.get(
      Uri.parse('$baseUrl/get-vpn-config'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final config = jsonDecode(response.body);
      if (config is Map<String, dynamic> &&
          config.containsKey('clientPrivateKey') &&
          config.containsKey('serverPublicKey') &&
          config.containsKey('serverAddress') &&
          config.containsKey('clientIp')) {
        logger.i('Received config: $config');
        return config;
      } else {
        logger.e('Invalid configuration: missing required fields - $config');
        throw Exception('Invalid configuration: missing required fields');
      }
    } else {
      logger.e('Error fetching config: ${response.statusCode} - ${response.body}');
      throw Exception('Ошибка получения конфигурации: ${response.body}');
    }
  }

  String _buildConfig(Map<String, dynamic> configData) {
    return '''
    [Interface]
    PrivateKey = ${configData['clientPrivateKey']}
    Address = ${configData['clientIp']}
    DNS = 8.8.8.8, 1.1.1.1

    [Peer]
    PublicKey = ${configData['serverPublicKey']}
    Endpoint = ${configData['serverAddress']}
    AllowedIPs = 0.0.0.0/0
    ''';
  }

  // Публичные методы
  Future<void> connect() async {
    try {
      await _initializationCompleter.future;
      final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        await authProvider.checkAuthStatus();
        if (!authProvider.isAuthenticated || authProvider.token == null) {
          throw Exception('Не авторизован или отсутствует токен');
        }
      }

      // Проверка пробного периода
      if (authProvider.trialEndDate != null) {
        final trialEnd = DateTime.parse(authProvider.trialEndDate!);
        if (!authProvider.isPaid && trialEnd.isBefore(DateTime.now())) {
          throw Exception('Срок действия пробного периода истёк');
        }
      } else if (!authProvider.isPaid) {
        throw Exception('Подключение заблокировано: требуется оплата подписки');
      }

      if (_wireguard == null) {
        await _initializeWireGuard();
        if (_wireguard == null) throw Exception('Failed to initialize WireGuard');
      }

      _isConnecting = true;
      notifyListeners();

      final stage = await _wireguard!.stage();
      if (stage == VpnStage.connected) {
        await _wireguard!.stopVpn();
        await Future.delayed(const Duration(seconds: 2));
      }

      await _clearTempFiles();
      final configData = await _fetchVpnConfig(AuthProvider.baseUrl, authProvider.token);
      final config = _buildConfig(configData);

      await _wireguard!.startVpn(
        serverAddress: configData['serverAddress'],
        wgQuickConfig: config,
        providerBundleIdentifier: 'com.shamovgk.vpn_app',
      );
      _isConnected = true;
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
    if (_wireguard == null) {
      logger.w('WireGuard not initialized, skipping disconnect');
      return;
    }

    _isConnecting = true;
    notifyListeners();
    try {
      await _wireguard!.stopVpn();
      _isConnected = false;
    } catch (e) {
      logger.e('Disconnect error: $e');
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
      trayHandler.updateTrayIconAndMenu();
    }
  }

  // Новый метод для проверки состояния
  bool isConnectionAllowed() {
    final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (authProvider.trialEndDate != null) {
      final trialEnd = DateTime.parse(authProvider.trialEndDate!);
      return authProvider.isPaid || (!authProvider.isPaid && trialEnd.isAfter(DateTime.now()));
    }
    return authProvider.isPaid;
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