// lib/features/auth/models/domain/user.dart
class User {
  final String username;
  final String? email;

  const User({
    required this.username,
    this.email,
  });
}
