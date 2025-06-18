import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  bool _isAuthenticated = false;
  bool _isPaid = false; 

  bool get isAuthenticated => _isAuthenticated;
  bool get isPaid => _isPaid;

  Future<void> login(String username, String password) async {
    if (username == 'admin' && password == 'password') {
      await _storage.write(key: 'auth_token', value: 'dummy_token');
      _isAuthenticated = true;
      _isPaid = await _storage.read(key: 'payment_status') == 'paid'; 
      notifyListeners();
    } else {
      throw Exception('Ошибка регистрации');
    }
  }
  Future<void> register(String username, String email, String password) async {
    if (username.isNotEmpty && email.isNotEmpty && password.length >= 6) {
      await _storage.write(key: 'auth_token', value: 'dummy_token');
      await _storage.write(key: 'payment_status', value: 'unpaid');
      _isAuthenticated = true;
      _isPaid = false;
      notifyListeners();
    } else {
      throw Exception('Ошибка регистрации');
    }
  }
  
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'payment_status');
    _isAuthenticated = false;
    _isPaid = false;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    _isAuthenticated = token != null;
    _isPaid = _isAuthenticated && await _storage.read(key: 'payment_status') == 'paid';
    notifyListeners();
  }

  Future<void> verifyPayment() async {
    await _storage.write(key: 'payment_status', value: 'paid');
    _isPaid = true;
    notifyListeners();
  }
}