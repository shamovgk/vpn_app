// lib/features/auth/models/dto/user_dto.dart
class UserDto {
  final String username;
  final String? email;
  const UserDto({required this.username, this.email});

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        username: (json['username'] as String?) ?? '',
        email: json['email'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'username': username,
        if (email != null) 'email': email,
      };
}

