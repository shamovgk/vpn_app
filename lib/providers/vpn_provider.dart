import 'package:flutter/material.dart';

class VpnProvider with ChangeNotifier {
  bool _isConnected = false;
  String? _selectedServer;

  bool get isConnected => _isConnected;
  String? get selectedServer => _selectedServer;

  void toggleConnection() {
    _isConnected = !_isConnected;
    notifyListeners();
  }

  void selectServer(String server) {
    _selectedServer = server;
    notifyListeners();
  }
}