import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wireguard_flutter/wireguard_flutter_platform_interface.dart';

class VpnProvider with ChangeNotifier {
  WireGuardFlutterInterface? wireguard;
  final _storage = const FlutterSecureStorage();
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
    if (kDebugMode) print('Starting WireGuard initialization...');
    if (wireguard != null) {
      print('WireGuard already initialized');
      _initializationCompleter.complete();
      return;
    }

    try {
      wireguard = WireGuardFlutter.instance;
      print('Instance retrieved: $wireguard');

      await wireguard!.initialize(interfaceName: tunnelName);
      print('WireGuard initialized with $tunnelName');

      await _clearTempFiles();

      _initializationCompleter.complete();
    } catch (e) {
      _initializationCompleter.completeError(e);
      print('Error initializing WireGuard: $e');
      if (e.toString().contains('Permission')) {
        print('Error: Run the app as Administrator on Windows.');
      } else if (e.toString().contains('WireGuard not installed')) {
        print('Error: WireGuard client is not installed.');
      }
      rethrow;
    }
  }

  Future<void> saveConfig({
    required String privateKey,
    required String serverPublicKey,
    required String serverAddress,
  }) async {
    await _storage.write(key: 'vpn_private_key_$tunnelName', value: privateKey);
    await _storage.write(key: 'vpn_server_public_key_$tunnelName', value: serverPublicKey);
    await _storage.write(key: 'vpn_server_address_$tunnelName', value: serverAddress);
  }

  Future<Map<String, String?>> getConfig() async {
    return {
      'privateKey': await _storage.read(key: 'vpn_private_key_$tunnelName'),
      'serverPublicKey': await _storage.read(key: 'vpn_server_public_key_$tunnelName'),
      'serverAddress': await _storage.read(key: 'vpn_server_address_$tunnelName'),
    };
  }

  Future<void> _clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFiles = tempDir.listSync().where((file) => file.path.contains('wg_'));
      for (var file in tempFiles) {
        print('Deleting temp file: ${file.path}');
        try {
          await file.delete();
        } catch (e) {
          print('Failed to delete temp file ${file.path}: $e');
        }
      }
      print('Temp files cleared successfully');
    } catch (e) {
      print('Error clearing temp files: $e');
    }
  }

  Future<void> connect() async {
    try {
      await _initializationCompleter.future;
    } catch (e) {
      print('Initialization failed: $e');
      rethrow;
    }

    if (wireguard == null) {
      print('WireGuard instance is null, reinitializing...');
      await _initializeWireGuard();
      if (wireguard == null) throw Exception('Failed to initialize WireGuard');
    }

    _isConnecting = true;
    notifyListeners();
    try {
      final stage = await wireguard!.stage();
      print('Current VPN stage: $stage');
      if (stage == VpnStage.connected) {
        print('Stopping existing VPN service...');
        await wireguard!.stopVpn();
        await Future.delayed(const Duration(seconds: 3));
      }

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
      print('VPN connected with new config');
    } catch (e) {
      _isConnected = false;
      print('Connection error: $e');
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (wireguard == null) {
      print('WireGuard not initialized, skipping disconnect');
      return;
    }

    _isConnecting = true;
    notifyListeners();
    try {
      await wireguard!.stopVpn();
      await Future.delayed(const Duration(seconds: 3)); // Увеличенная задержка
      _isConnected = false;
      print('VPN disconnected');
    } catch (e) {
      print('Disconnect error: $e');
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (isConnected) {
      disconnect().then((_) {
        print('VPN disconnected on provider dispose');
      }).catchError((e) {
        print('Error disconnecting VPN on provider dispose: $e');
      });
    }
    super.dispose();
  }
}