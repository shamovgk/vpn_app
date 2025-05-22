import 'package:flutter/material.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VpnProvider with ChangeNotifier {
  final wireguard = WireGuardFlutter.instance;
  final _storage = const FlutterSecureStorage();
  bool _isConnected = false;
  bool _isConnecting = false;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  Future<void> saveConfig({
    required String privateKey,
    required String serverPublicKey,
    required String serverAddress,
  }) async {
    await _storage.write(key: 'vpn_private_key', value: privateKey);
    await _storage.write(key: 'vpn_server_public_key', value: serverPublicKey);
    await _storage.write(key: 'vpn_server_address', value: serverAddress);
  }

  Future<Map<String, String>> getConfig() async {
    final privateKey = await _storage.read(key: 'vpn_private_key') ?? '';
    final serverPublicKey = await _storage.read(key: 'vpn_server_public_key') ?? '';
    final serverAddress = await _storage.read(key: 'vpn_server_address') ?? '';
    return {
      'privateKey': privateKey,
      'serverPublicKey': serverPublicKey,
      'serverAddress': serverAddress,
    };
  }

  Future<void> connect() async {
    _isConnecting = true;
    notifyListeners();
    try {
      final configData = await getConfig();
      if (configData['privateKey']!.isEmpty || configData['serverPublicKey']!.isEmpty || configData['serverAddress']!.isEmpty) {
        throw Exception('Конфигурация не настроена');
      }

      final config = '''
      [Interface]
      PrivateKey = ${configData['privateKey']}
      Address = 10.8.0.2/24
      DNS = 8.8.8.8

      [Peer]
      PublicKey = ${configData['serverPublicKey']}
      Endpoint = ${configData['serverAddress']}
      AllowedIPs = 0.0.0.0/0
      ''';
      await wireguard.initialize(interfaceName: 'wg0');
      await wireguard.startVpn(
        serverAddress: configData['serverAddress']!,
        wgQuickConfig: config,
        providerBundleIdentifier: 'com.shamovgk.vpn_app',
      );
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _isConnecting = true;
    notifyListeners();
    try {
      await wireguard.stopVpn();
      _isConnected = false;
    } catch (e) {
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }
}