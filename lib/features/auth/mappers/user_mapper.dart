// lib/features/auth/mappers/user_mapper.dart
import '../models/dto/user_dto.dart';
import '../models/domain/user.dart';

User userFromDto(UserDto dto) => User(
  username: dto.username,
  email: dto.email,
);

UserDto userToDto(User user) => UserDto(
  username: user.username,
  email: user.email,
);
