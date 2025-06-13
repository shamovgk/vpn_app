import 'dart:async';
import 'package:flutter/foundation.dart'; // Для kDebugMode
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wireguard_flutter/wireguard_flutter_platform_interface.dart'; // Для интерфейса

class VpnProvider with ChangeNotifier {
  WireGuardFlutterInterface? wireguard; // Nullable
  final _storage = const FlutterSecureStorage();
  bool _isConnecting = false;
  bool _isConnected = false;
  final Completer<void> _initializationCompleter = Completer<void>(); // Синхронизация

  static const String tunnelName = 'vpn_app_tunnel'; // Фиксированное имя туннеля

  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;

  // Инициализация WireGuardFlutter
  VpnProvider() {
    _initializeWireGuard();
  }

  Future<void> _initializeWireGuard() async {
    if (kDebugMode) print('Starting WireGuard initialization...');
    if (wireguard != null) {
      if (kDebugMode) print('WireGuard already initialized');
      _initializationCompleter.complete();
      return;
    }

    try {
      wireguard = WireGuardFlutter.instance;
      if (kDebugMode) print('Instance retrieved: $wireguard');

      await wireguard!.initialize(interfaceName: tunnelName);
      if (kDebugMode) print('WireGuard initialized with $tunnelName');

      // Очистка старых временных файлов при инициализации
      await _clearTempFiles();

      _initializationCompleter.complete();
    } catch (e) {
      _initializationCompleter.completeError(e);
      if (kDebugMode) print('Error initializing WireGuard: $e');
      if (e.toString().contains('Permission')) {
        if (kDebugMode) print('Error: Run the app as Administrator on Windows.');
      } else if (e.toString().contains('WireGuard not installed')) {
        if (kDebugMode) print('Error: WireGuard client is not installed.');
      }
      rethrow;
    }
  }

  // Сохранение конфигурации
  Future<void> saveConfig({
    required String privateKey,
    required String serverPublicKey,
    required String serverAddress,
  }) async {
    await _storage.write(key: 'vpn_private_key_$tunnelName', value: privateKey);
    await _storage.write(key: 'vpn_server_public_key_$tunnelName', value: serverPublicKey);
    await _storage.write(key: 'vpn_server_address_$tunnelName', value: serverAddress);
  }

  // Получение конфигурации
  Future<Map<String, String?>> getConfig() async {
    return {
      'privateKey': await _storage.read(key: 'vpn_private_key_$tunnelName'),
      'serverPublicKey': await _storage.read(key: 'vpn_server_public_key_$tunnelName'),
      'serverAddress': await _storage.read(key: 'vpn_server_address_$tunnelName'),
    };
  }

  // Очистка временных файлов
  Future<void> _clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFiles = tempDir.listSync().where((file) => file.path.contains('wg_'));
      for (var file in tempFiles) {
        if (kDebugMode) print('Deleting temp file: ${file.path}');
        try {
          await file.delete(); // Асинхронное удаление
        } catch (e) {
          if (kDebugMode) print('Failed to delete temp file ${file.path}: $e');
        }
      }
      if (kDebugMode) print('Temp files cleared successfully');
    } catch (e) {
      if (kDebugMode) print('Error clearing temp files: $e');
    }
  }

  // Подключение к VPN
  Future<void> connect() async {
    try {
      await _initializationCompleter.future; // Ждём завершения инициализации
    } catch (e) {
      if (kDebugMode) print('Initialization failed: $e');
      rethrow;
    }

    if (wireguard == null) {
      if (kDebugMode) print('WireGuard instance is null, reinitializing...');
      await _initializeWireGuard();
      if (wireguard == null) throw Exception('Failed to initialize WireGuard');
    }

    _isConnecting = true;
    notifyListeners();
    try {
      final stage = await wireguard!.stage();
      if (kDebugMode) print('Current VPN stage: $stage');
      if (stage == VpnStage.connected) {
        if (kDebugMode) print('Stopping existing VPN service...');
        await wireguard!.stopVpn(); // Остановка текущей службы
        await Future.delayed(const Duration(seconds: 3)); // Задержка
      }

      // Очистка временных файлов перед новым подключением
      await _clearTempFiles();

      final configData = await getConfig();
      if (configData['privateKey']!.isEmpty || configData['serverPublicKey']!.isEmpty || configData['serverAddress']!.isEmpty) {
        throw Exception('Конфигурация не настроена');
      }

      final config = '''
      [Interface]
      PrivateKey = ${configData['privateKey']}
      Address = 10.0.0.2/32
      DNS = 8.8.8.8, 1.1.1.1
      MTU = 1280

      [Peer]
      PublicKey = ${configData['serverPublicKey']}
      Endpoint = ${configData['serverAddress']}
      AllowedIPs = 0.0.0.0/0
      ''';

      await wireguard!.startVpn(
        serverAddress: configData['serverAddress']!,
        wgQuickConfig: config,
        providerBundleIdentifier: 'com.shamovgk.vpn_app',
      );
      _isConnected = true;
      if (kDebugMode) print('VPN connected with new config');
    } catch (e) {
      _isConnected = false;
      if (kDebugMode) print('Connection error: $e');
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  // Отключение VPN
  Future<void> disconnect() async {
    if (wireguard == null) {
      if (kDebugMode) print('WireGuard not initialized, skipping disconnect');
      return;
    }

    _isConnecting = true;
    notifyListeners();
    try {
      await wireguard!.stopVpn();
      _isConnected = false;
      if (kDebugMode) print('VPN disconnected');
    } catch (e) {
      if (kDebugMode) print('Disconnect error: $e');
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }
}