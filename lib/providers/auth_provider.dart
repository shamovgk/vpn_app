import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/main.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
  String? _trialEndDate;
  int _deviceCount = 0;
  int _subscriptionLevel = 0;
  String? _deviceToken;
  String? _deviceModel;
  String? _deviceOS;

  // Геттеры
  bool get isAuthenticated => _isAuthenticated;
  bool get isPaid => _isPaid;
  bool get emailVerified => _emailVerified;
  bool get showVerification => _showVerification;
  String? get username => _username;
  String? get email => _email;
  String? get vpnKey => _vpnKey;
  String? get token => _token;
  String? get trialEndDate => _trialEndDate;
  int get deviceCount => _deviceCount;
  int get subscriptionLevel => _subscriptionLevel;
  String? get deviceToken => _deviceToken;
  String? get deviceModel => _deviceModel;
  String? get deviceOS => _deviceOS;

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
    _trialEndDate = userData['trial_end_date'];
    _deviceCount = userData['device_count'] ?? 0;
    _subscriptionLevel = userData['subscription_level'] ?? 0;
    _deviceToken = await _getDeviceToken();
    _deviceModel = await _getDeviceModel();
    _deviceOS = await _getDeviceOS();
    await _storage.write(key: 'trial_end_date', value: _trialEndDate);
    notifyListeners();
  }

  Future<void> _clearAuthState() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'trial_end_date');
    _isAuthenticated = false;
    _isPaid = false;
    _emailVerified = false;
    _username = null;
    _email = null;
    _vpnKey = null;
    _token = null;
    _trialEndDate = null;
    _deviceCount = 0;
    _subscriptionLevel = 0;
    _deviceToken = null;
    _deviceModel = null;
    _deviceOS = null;
    notifyListeners();
  }

  Future<String> _getDeviceToken() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.windows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.deviceId;
    } else if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'ios_default_id';
    }
    return 'default_device_id';
  }

  Future<String?> _getDeviceModel() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.windows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.computerName;
    } else if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.model;
    }
    return 'Unknown Model';
  }

  Future<String?> _getDeviceOS() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.windows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return 'Windows ${windowsInfo.displayVersion}';
    } else if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      return 'Android ${androidInfo.version.release}';
    } else if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return 'iOS ${iosInfo.systemVersion}';
    }
    return 'Unknown OS';
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
    final savedTrialEndDate = await _storage.read(key: 'trial_end_date');
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/validate-token?token=$token'),
          headers: _headers,
        );
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body) as Map<String, dynamic>;
          await _updateAuthState(userData, token);
          if (savedTrialEndDate != null && userData['trial_end_date'] == null) {
            _trialEndDate = savedTrialEndDate;
            notifyListeners();
          }
        } else {
          await _clearAuthState();
        }
      } catch (e) {
        logger.e('Error checking auth status: $e');
        await _clearAuthState();
        throw Exception('Error checking auth status: $e');
      }
    } else {
      await _clearAuthState();
    }
  }

  Future<void> checkAuthAndTrialStatus() async {
    await checkAuthStatus();
    final savedTrialEndDate = await _storage.read(key: 'trial_end_date');
    if (_trialEndDate == null && savedTrialEndDate != null) {
      _trialEndDate = savedTrialEndDate;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    try {
      _deviceToken = await _getDeviceToken();
      _deviceModel = await _getDeviceModel();
      _deviceOS = await _getDeviceOS();
      final response = await _makeApiRequest('login', body: {
        'username': username,
        'password': password,
        'device_token': _deviceToken,
        'device_model': _deviceModel,
        'device_os': _deviceOS,
      });
      if (response['id'] != null) {
        await _updateAuthState(response, response['auth_token']);
      } else {
        throw Exception('Неверный пароль или пользователь');
      }
    } on Exception catch (e) {
      if (e.toString().contains('Email not verified')) {
        throw Exception('Пожалуйста, проверьте email для верификации');
      } else if (e.toString().contains('Срок действия пробного периода истёк')) {
        throw Exception('Срок действия пробного периода истёк');
      } else if (e.toString().contains('Достигнут лимит устройств')) {
        throw Exception('Достигнут лимит устройств, удалите устройство или обновите подписку');
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
        if (error.contains('duplicate username')) {
          throw Exception('Такой логин уже существует');
        } else if (error.contains('duplicate email')) {
          throw Exception('Этот email уже используется');
        } else if (error.contains('pending verification username')) {
          throw Exception('Этот логин уже ожидает верификации');
        } else if (error.contains('pending verification email')) {
          throw Exception('Этот email уже ожидает верификации');
        } else if (error.contains('empty username')) {
          throw Exception('Логин не может быть пустым');
        } else if (error.contains('email send failed')) {
          throw Exception('Не удалось отправить email с кодом верификации');
        }
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
      if (e.toString().contains('invalid code')) {
        throw Exception('Неверный код верификации');
      } else if (e.toString().contains('expired code')) {
        throw Exception('Срок действия кода верификации истёк');
      } else if (e.toString().contains('not found')) {
        throw Exception('Пользователь или email не найдены в ожидающих верификации');
      } else if (e.toString().contains('verification failed')) {
        throw Exception('Не удалось завершить верификацию');
      }
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
      throw Exception('Token not found');
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
      if (e.toString().contains('401')) {
        throw Exception('Token is required');
      } else if (e.toString().contains('expired token')) {
        throw Exception('Invalid or expired token');
      } else if (e.toString().contains('trial expired')) {
        throw Exception('Trial period expired');
      }
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
      if (e.toString().contains('invalid code')) {
        throw Exception('Неверный или истёкший код восстановления');
      } else if (e.toString().contains('not found')) {
        throw Exception('Пользователь не найден');
      } else if (e.toString().contains('update failed')) {
        throw Exception('Не удалось обновить пароль');
      }
      throw Exception('Ошибка сброса пароля: $e');
    }
  }

  Future<void> removeDevice(String deviceToken) async {
    if (_token == null) throw Exception('Не авторизован');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/remove-device'),
        headers: {..._headers, 'Authorization': 'Bearer $_token'},
        body: jsonEncode({'user_id': _username, 'device_token': deviceToken}),
      );
      if (response.statusCode == 200) {
        _deviceCount--; // Уменьшаем локальный счётчик
        notifyListeners();
      } else {
        throw Exception('Ошибка удаления устройства: ${response.body}');
      }
    } catch (e) {
      logger.e('Error removing device: $e');
      rethrow;
    }
  }

  void resetVerificationState() {
    _showVerification = false;
    notifyListeners();
  }
}