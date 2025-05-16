import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class VpnProvider with ChangeNotifier {
  bool _isConnected = false;
  String? _selectedServer;
  String? _selectedPlan;
  bool _isPurchasing = false;
  String? _purchaseError;

  bool get isConnected => _isConnected;
  String? get selectedServer => _selectedServer;
  String? get selectedPlan => _selectedPlan;
  bool get isPurchasing => _isPurchasing;
  String? get purchaseError => _purchaseError;

  void toggleConnection() {
    _isConnected = !_isConnected;
    notifyListeners();
  }

  void selectServer(String server) {
    _selectedServer = server;
    notifyListeners();
  }

  void selectPlan(String plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  void setPurchasing(bool value) {
    _isPurchasing = value;
    notifyListeners();
  }

  void setPurchaseError(String? error) {
    _purchaseError = error;
    notifyListeners();
  }
}