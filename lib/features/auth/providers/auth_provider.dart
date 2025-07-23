import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/features/vpn/providers/vpn_provider.dart';
import '../../../core/api_service.dart';
import '../../../core/token_provider.dart'; // !
import '../models/user.dart';
import '../services/auth_service.dart';

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthProvider(apiService: apiService, ref: ref);
});

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Ref ref;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthProvider({required ApiService apiService, required this.ref})
      : _authService = AuthService(apiService) {
    _loadToken();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => ref.read(tokenProvider) != null && _user != null;
  bool get isInitialized => _isInitialized;

  Future<void> _loadToken() async {
    final token = await _storage.read(key: 'token');
    ref.read(tokenProvider.notifier).state = token;
    if (token != null) {
      await validateToken();
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> register(String username, String email, String password) async {
    _setLoading(true);
    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
      );
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyEmail(
      String username, String email, String verificationCode) async {
    _setLoading(true);
    try {
      await _authService.verifyEmail(
        username: username,
        email: email,
        verificationCode: verificationCode,
      );
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(
    String username,
    String password, {
    String? deviceToken,
    String? deviceModel,
    String? deviceOS,
  }) async {
    _setLoading(true);
    try {
      final response = await _authService.login(
        username: username,
        password: password,
        deviceToken: deviceToken,
        deviceModel: deviceModel,
        deviceOS: deviceOS,
      );
      final token = response['token'];
      final user = User.fromJson(response['user']);
      if (token == null || token is! String) {
        throw ApiException('Не удалось получить токен!');
      }
      ref.read(tokenProvider.notifier).state = token;
      await _storage.write(key: 'token', value: token);
      _user = user;
      _errorMessage = null;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> validateToken() async {
    _setLoading(true);
    try {
      final user = await _authService.validateToken();
      _user = user;
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
      // disconnect VPN перед logout
      await ref.read(vpnProvider.notifier).disconnect();
      await _authService.logout();
    } catch (_) {}
    _user = null;
    ref.read(tokenProvider.notifier).state = null;
    await _storage.delete(key: 'token');
    notifyListeners();
  }

  Future<void> forgotPassword(String username) async {
    _setLoading(true);
    try {
      await _authService.forgotPassword(username);
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(
      String username, String resetCode, String newPassword) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(
        username: username,
        resetCode: resetCode,
        newPassword: newPassword,
      );
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
