import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/main.dart';
import '../providers/vpn_provider.dart';

final logger = Logger();
class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  bool _isAuthenticated = false;
  bool _isPaid = false;
  bool _emailVerified = false;
  String? _username;
  String? _vpnKey;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  bool get isPaid => _isPaid;
  bool get emailVerified => _emailVerified;
  String? get username => _username;
  String? get vpnKey => _vpnKey;
  String? get token => _token;

  static const String _baseUrl = 'http://95.214.10.8:3000';
  static String get baseUrl => _baseUrl;
  
  final bool _isTestMode = false;

  Future<void> checkAuthStatus() async {
    if (_isTestMode) {
      _isAuthenticated = true;
      _isPaid = true;
      _emailVerified = true; // Тестовый режим: верификация сразу пройдена
      _username = 'test_user';
      _vpnKey = 'QO4kryQQIaEXvCo2akiLmia25Y/q2L0kRFrbD1kATmo=';
      _token = 'test_token_abc123';
      logger.i('Test mode: Authenticated as $username with VPN key: $_vpnKey');
    } else {
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
          _emailVerified = (userData['email_verified'] as int) == 1; // Обновляем статус
          _username = userData['username'];
          _vpnKey = userData['vpn_key'];
          _token = token;
          notifyListeners();
        } else {
          await _storage.delete(key: 'auth_token');
          _isAuthenticated = false;
          _isPaid = false;
          _emailVerified = false;
          _username = null;
          _vpnKey = null;
          _token = null;
          notifyListeners();
        }
      } else {
        _isAuthenticated = false;
        _isPaid = false;
        _emailVerified = false;
        _username = null;
        _vpnKey = null;
        _token = null;
        notifyListeners();
      }
    }
    notifyListeners();
  }

Future<void> login(String username, String password) async {
  if (_isTestMode) {
    if (username == 'test' && password == 'test') {
      _isAuthenticated = true;
      _isPaid = true;
      _emailVerified = true;
      _username = 'test_user';
      _vpnKey = 'QO4kryQQIaEXvCo2akiLmia25Y/q2L0kRFrbD1kATmo=';
      _token = 'test_token_abc123';
      logger.i('Test mode: Login successful for $username');
      notifyListeners();
    } else {
      throw Exception('Неверный тестовый логин или пароль (используй "test"/"test")');
    }
  } else {
    logger.i('Attempting login for username: $username');
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    logger.i('Login response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      if (userData['id'] != null) {
        logger.i('Setting auth token and state');
        await _storage.write(key: 'auth_token', value: userData['auth_token']);
        _isAuthenticated = true;
        _isPaid = (userData['is_paid'] as int) == 1;
        _emailVerified = (userData['email_verified'] as int) == 1;
        _username = userData['username'];
        _vpnKey = userData['vpn_key'];
        _token = userData['auth_token'];
        logger.i('Authenticated: $_isAuthenticated, Paid: $_isPaid, Email Verified: $_emailVerified');
        notifyListeners();
      } else {
        throw Exception('Неверный пароль или пользователь');
      }
    } else if (response.statusCode == 403 && response.body.contains('Email not verified')) {
      throw Exception('Пожалуйста, проверьте email для верификации');
    } else {
      throw Exception('Ошибка логина: ${response.body}');
    }
  }
  notifyListeners();
}

  Future<void> register(String username, String email, String password) async {
    if (_isTestMode) {
      _isAuthenticated = false;
      _isPaid = false;
      _emailVerified = false;
      _username = username;
      _vpnKey = 'QO4kryQQIaEXvCo2akiLmia25Y/q2L0kRFrbD1kATmo=';
      logger.i('Test mode: Registered as $username');
      notifyListeners();
    } else {
      logger.i('Attempting registration for username: $username, email: $email');
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password, 'email': email}),
      );
      logger.i('Register response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isAuthenticated = false;
        _isPaid = false;
        _emailVerified = false;
        _username = data['username'];
        _vpnKey = data['vpn_key'];
        notifyListeners();
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body)['error'];
        throw Exception('Ошибка регистрации: $error');
      } else {
        throw Exception('Ошибка регистрации: ${response.body}');
      }
    }
  }

  Future<void> verifyEmail(String username, String email, String verificationCode) async {
    if (_isTestMode) {
      _emailVerified = true;
      logger.i('Test mode: Email verified for $username');
      notifyListeners();
    } else {
      logger.i('Attempting email verification for username: $username');
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'email': email, 'verificationCode': verificationCode}),
      );
      logger.i('Verify email response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        _emailVerified = true;
        notifyListeners();
      } else {
        throw Exception('Ошибка верификации email: ${response.body}');
      }
    }
  }

Future<void> logout() async {
  final vpnProvider = Provider.of<VpnProvider>(navigatorKey.currentContext!, listen: false);
  if (vpnProvider.isConnected) {
    await vpnProvider.disconnect();
  }

  if (_isTestMode) {
    _isAuthenticated = false;
    _isPaid = false;
    _emailVerified = false;
    _username = null;
    _vpnKey = null;
    _token = null;
    logger.i('Test mode: Logout successful');
  } else {
    if (_token != null) {
      final response = await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      if (response.statusCode == 200) {
        await _storage.delete(key: 'auth_token');
        _isAuthenticated = false;
        _isPaid = false;
        _emailVerified = false;
        _username = null;
        _vpnKey = null;
        _token = null;
        notifyListeners();
      } else {
        throw Exception('Ошибка выхода: ${response.body}');
      }
    } else {
      await _storage.delete(key: 'auth_token');
      _isAuthenticated = false;
      _isPaid = false;
      _emailVerified = false;
      _username = null;
      _vpnKey = null;
      _token = null;
      notifyListeners();
    }
  }
  notifyListeners();
}

  Future<void> verifyPayment() async {
    if (_isTestMode) {
      _isPaid = true;
      logger.i('Test mode: Payment verified');
      notifyListeners();
    } else {
      if (_token == null) throw Exception('Не авторизован');
      final response = await http.put(
        Uri.parse('$_baseUrl/pay'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
        body: jsonEncode({'is_family': false}),
      );
      if (response.statusCode == 200) {
        _isPaid = true;
        notifyListeners();
      } else {
        throw Exception('Ошибка подтверждения оплаты: ${response.body}');
      }
    }
  }
}