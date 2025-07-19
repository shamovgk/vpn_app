
import '../../../core/api_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiService api;

  AuthService(this.api);

  Future<User> login({
    required String username,
    required String password,
    String? deviceToken,
    String? deviceModel,
    String? deviceOS,
  }) async {
    final body = {
      'username': username,
      'password': password,
      if (deviceToken != null) 'device_token': deviceToken,
      if (deviceModel != null) 'device_model': deviceModel,
      if (deviceOS != null) 'device_os': deviceOS,
    };
    final res = await api.post('/auth/login', body);
    return User.fromJson(res);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await api.post('/auth/register', {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  Future<void> verifyEmail({
    required String username,
    required String email,
    required String verificationCode,
  }) async {
    await api.post('/auth/verify-email', {
      'username': username,
      'email': email,
      'verificationCode': verificationCode,
    });
  }

  Future<void> logout() async {
    await api.post('/auth/logout', {}, auth: true);
  }

  Future<User> validateToken(String token) async {
    final res = await api.get('/auth/validate-token?token=$token', auth: true);
    return User.fromJson(res);
  }

  Future<void> forgotPassword(String username) async {
    await api.post('/auth/forgot-password', {'username': username});
  }

  Future<void> resetPassword({
    required String username,
    required String resetCode,
    required String newPassword,
  }) async {
    await api.post('/auth/reset-password', {
      'username': username,
      'resetCode': resetCode,
      'newPassword': newPassword,
    });
  }
}
