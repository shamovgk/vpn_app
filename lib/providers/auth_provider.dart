import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  bool _isAuthenticated = false;
  bool _isPaid = false;
  String? _username;
  String? _vpnKey;

  bool get isAuthenticated => _isAuthenticated;
  bool get isPaid => _isPaid;
  String? get username => _username;
  String? get vpnKey => _vpnKey;

  static const String _baseUrl = 'http://95.214.10.8:3000';

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      final response = await http.get(
        Uri.parse('$_baseUrl/validate-token?token=$token'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _isAuthenticated = true;
        _isPaid = (userData['is_paid'] as int) == 1;
        _username = userData['username'];
        _vpnKey = userData['vpn_key'];
        notifyListeners();
      } else {
        await _storage.delete(key: 'auth_token');
        _isAuthenticated = false;
      }
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    print('Attempting login for username: $username');
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    print('Login response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      print('User data: $userData');
      if (userData['id'] != null) {
        print('Setting auth token and state');
        await _storage.write(key: 'auth_token', value: userData['auth_token']);
        _isAuthenticated = true;
        _isPaid = (userData['is_paid'] as int) == 1;
        _username = userData['username'];
        _vpnKey = userData['vpn_key'];
        print('Authenticated: $_isAuthenticated, Paid: $_isPaid');
        notifyListeners();
      } else {
        throw Exception('Неверный пароль или пользователь');
      }
    } else {
      throw Exception('Ошибка логина: ${response.body}');
    }
  }

  Future<void> register(String username, String email, String password) async {
    print('Attempting registration for username: $username, email: $email');
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password, 'email': email}),
    );
    print('Register response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: 'payment_status', value: 'unpaid');
      _isAuthenticated = false;
      _isPaid = false;
      _username = data['username'];
      notifyListeners();
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body)['error'];
      throw Exception('Ошибка регистрации: $error');
    } else {
      throw Exception('Ошибка регистрации: ${response.body}');
    }
  }

 Future<void> logout() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      final response = await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
      if (response.statusCode == 200) {
        await _storage.delete(key: 'auth_token');
        await _storage.delete(key: 'payment_status');
        _isAuthenticated = false;
        _isPaid = false;
        _username = null;
        _vpnKey = null;
        notifyListeners();
      } else {
        throw Exception('Ошибка выхода: ${response.body}');
      }
    } else {
      _isAuthenticated = false;
      _isPaid = false;
      _username = null;
      _vpnKey = null;
      notifyListeners();
    }
  }
 Future<void> verifyPayment() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      final response = await http.put(
        Uri.parse('$_baseUrl/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': token, 'is_family': false}),
      );
      if (response.statusCode == 200) {
        await _storage.write(key: 'payment_status', value: 'paid');
        _isPaid = true;
        notifyListeners();
      } else {
        throw Exception('Ошибка подтверждения оплаты');
      }
    }
  }
}