import 'package:flutter/material.dart';
import '../models/vpn_server.dart';

class VpnProvider with ChangeNotifier {
  bool _isConnected = false;
  bool _isConnecting = false;
  final VpnServer _server = VpnServer(
    ipAddress: 'your_server_ip', // Замени на реальный IP сервера
    publicKey: 'your_public_key', // Замени на реальный ключ
  );

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  VpnServer get server => _server;

  Future<void> connect() async {
    _isConnecting = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2)); // Симуляция
    _isConnected = true;
    _isConnecting = false;
    notifyListeners();
  }

  Future<void> disconnect() async {
    _isConnecting = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
  }
}