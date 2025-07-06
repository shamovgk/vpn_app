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
  bool _showVerification = false;
  String? _username;
  String? _email;
  String? _vpnKey;
  String? _token;

  // Геттеры
  bool get isAuthenticated => _isAuthenticated;
  bool get isPaid => _isPaid;
  bool get emailVerified => _emailVerified;
  bool get showVerification => _showVerification;
  String? get username => _username;
  String? get email => _email;
  String? get vpnKey => _vpnKey;
  String? get token => _token;

  // Константы
  static const String _baseUrl = 'http://95.214.10.8:3000';
  static String get baseUrl => _baseUrl;
  static const Map<String, String> _headers = {'Content-Type': 'application/json'};

  // Утилитарные методы
  Future<Map<String, dynamic>> _makeApiRequest(String endpoint, {Map<String, dynamic>? body, String? token}) async {
    final headers = {..._headers};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    logger.i('API request to $endpoint: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API error: ${response.body}');
    }
  }

  Future<void> _updateAuthState(Map<String, dynamic> userData, String? token) async {
    await _storage.write(key: 'auth_token', value: token ?? '');
    _isAuthenticated = true;
    _isPaid = (userData['is_paid'] as int) == 1;
    _emailVerified = (userData['email_verified'] as int) == 1;
    _username = userData['username'];
    _vpnKey = userData['vpn_key'];
    _token = token;
    notifyListeners();
  }

  Future<void> _clearAuthState() async {
    await _storage.delete(key: 'auth_token');
    _isAuthenticated = false;
    _isPaid = false;
    _emailVerified = false;
    _username = null;
    _email = null;
    _vpnKey = null;
    _token = null;
    notifyListeners();
  }

  // Публичные методы
  void setRegistrationData(String username, String email) {
    _username = username;
    _email = email;
    notifyListeners();
  }

  void resetRegistrationData() {
    _username = null;
    _email = null;
    _showVerification = false;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/validate-token?token=$token'),
          headers: _headers,
        );
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body) as Map<String, dynamic>;
          await _updateAuthState(userData, token);
        } else {
          await _clearAuthState();
        }
      } catch (e) {
        logger.e('Error checking auth status: $e');
        await _clearAuthState();
      }
    } else {
      await _clearAuthState();
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final response = await _makeApiRequest('login', body: {'username': username, 'password': password});
      if (response['id'] != null) {
        await _updateAuthState(response, response['auth_token']);
      } else {
        throw Exception('Неверный пароль или пользователь');
      }
    } on Exception catch (e) {
      if (e.toString().contains('Email not verified')) {
        throw Exception('Пожалуйста, проверьте email для верификации');
      }
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      final response = await _makeApiRequest('register', body: {
        'username': username,
        'password': password,
        'email': email,
      });
      _isAuthenticated = false;
      _isPaid = false;
      _emailVerified = false;
      _username = response['username'];
      _email = email;
      _vpnKey = response['vpn_key'];
      _showVerification = true;
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('400')) {
        final error = jsonDecode((e.toString().split(': ')[1]))['error'];
        throw Exception('Ошибка регистрации: $error');
      }
      throw Exception('Ошибка регистрации: $e');
    }
  }

  Future<void> verifyEmail(String username, String email, String verificationCode) async {
    try {
      await _makeApiRequest('verify-email', body: {
        'username': username,
        'email': email,
        'verificationCode': verificationCode,
      });
      _emailVerified = true;
      notifyListeners();
    } catch (e) {
      throw Exception('Ошибка верификации email: $e');
    }
  }

  Future<void> logout() async {
    final vpnProvider = Provider.of<VpnProvider>(navigatorKey.currentContext!, listen: false);
    if (vpnProvider.isConnected) {
      await vpnProvider.disconnect();
    }
    try {
      if (_token != null) {
        await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: {..._headers, 'Authorization': 'Bearer $_token'},
        );
      }
      await _clearAuthState();
    } catch (e) {
      logger.e('Error during logout: $e');
      await _clearAuthState();
    }
  }

  Future<void> verifyPayment() async {
    if (_token == null) throw Exception('Не авторизован');
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/pay'),
        headers: {..._headers, 'Authorization': 'Bearer $_token'},
        body: jsonEncode({'is_family': false}),
      );
      if (response.statusCode == 200) {
        _isPaid = true;
        notifyListeners();
      } else {
        throw Exception('Ошибка подтверждения оплаты: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String username, String resetCode, String newPassword) async {
    if (username.isEmpty || resetCode.isEmpty || newPassword.isEmpty) {
      throw Exception('All fields (username, reset code, new password) are required');
    }
    try {
      await _makeApiRequest('reset-password', body: {
        'username': username,
        'resetCode': resetCode,
        'newPassword': newPassword,
      });
      notifyListeners();
    } catch (e) {
      throw Exception('Ошибка сброса пароля: $e');
    }
  }

  void resetVerificationState() {
    _showVerification = false;
    notifyListeners();
  }
}