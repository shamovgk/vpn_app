// lib/features/auth/models/domain/login_result.dart
import 'user.dart';

class LoginResult {
  final String token;
  final User user;

  const LoginResult({
    required this.token,
    required this.user,
  });
}
