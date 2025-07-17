import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final ApiService apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({required this.apiService}) {
    _loadToken();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _token != null && _user != null;
  String? get token => _token; // <-- Важно!
  static String get baseUrl => ApiService.baseUrl;

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'token');
    if (_token != null) {
      await validateToken();
    }
    notifyListeners();
  }

  Future<void> register(String username, String email, String password) async {
    _setLoading(true);
    try {
      await apiService.post('/auth/register', {
        'username': username,
        'email': email,
        'password': password,
      });
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyEmail(String username, String email, String verificationCode) async {
    _setLoading(true);
    try {
      await apiService.post('/auth/verify-email', {
        'username': username,
        'email': email,
        'verificationCode': verificationCode,
      });
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String username, String password,
      {String? deviceToken, String? deviceModel, String? deviceOS}) async {
    _setLoading(true);
    try {
      final body = {
        'username': username,
        'password': password,
      };
      if (deviceToken != null) body['device_token'] = deviceToken;
      if (deviceModel != null) body['device_model'] = deviceModel;
      if (deviceOS != null) body['device_os'] = deviceOS;

      final res = await apiService.post('/auth/login', body);
      final token = res['auth_token'];
      if (token == null) throw ApiException('Сервер не вернул токен!');
      _token = token;
      await apiService.setToken(token);
      await _storage.write(key: 'token', value: token);
      _user = User.fromJson(res);
      _errorMessage = null;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> validateToken() async {
    if (_token == null) return;
    _setLoading(true);
    try {
      final res = await apiService.get('/auth/validate-token?token=$_token', auth: true);
      _user = User.fromJson(res);
      _errorMessage = null;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      await logout();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await apiService.post('/auth/logout', {}, auth: true);
      }
    } catch (_) {}
    _user = null;
    _token = null;
    await apiService.setToken(null);
    await _storage.delete(key: 'token');
    notifyListeners();
  }

  Future<void> forgotPassword(String username) async {
    _setLoading(true);
    try {
      await apiService.post('/auth/forgot-password', {'username': username});
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String username, String resetCode, String newPassword) async {
    _setLoading(true);
    try {
      await apiService.post('/auth/reset-password', {
        'username': username,
        'resetCode': resetCode,
        'newPassword': newPassword,
      });
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
