import 'package:flutter/material.dart';
import '../models/vpn_server.dart';

class VpnProvider with ChangeNotifier {
  bool _isConnected = false;
  bool _isConnecting = false;
  VpnServer? _selectedServer;
  final List<VpnServer> _servers = [
    VpnServer(name: 'USA Server', country: 'United States', ipAddress: '192.168.1.100', publicKey: 'xX...Yy=='),
    VpnServer(name: 'EU Server', country: 'Germany', ipAddress: '192.168.1.101', publicKey: 'yY...Zz=='),
  ];

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  VpnServer? get selectedServer => _selectedServer;
  List<VpnServer> get servers => _servers;

  void selectServer(VpnServer server) {
    _selectedServer = server;
    notifyListeners();
  }

  Future<void> connect() async {
    if (_selectedServer == null) throw Exception('No server selected');
    _isConnecting = true;
    notifyListeners();
    // Заглушка для подключения
    await Future.delayed(const Duration(seconds: 2)); // Симуляция задержки
    _isConnected = true;
    _isConnecting = false;
    notifyListeners();
  }

  Future<void> disconnect() async {
    _isConnecting = true;
    notifyListeners();
    // Заглушка для отключения
    await Future.delayed(const Duration(seconds: 1));
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
  }
}