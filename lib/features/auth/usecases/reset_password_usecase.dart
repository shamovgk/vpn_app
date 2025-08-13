// lib/features/auth/usecases/reset_password_usecase.dart
import 'package:dio/dio.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repo;
  ResetPasswordUseCase(this.repo);

  Future<void> call(String username, String resetCode, String newPassword, {CancelToken? cancelToken}) {
    return repo.resetPassword(
      username: username,
      resetCode: resetCode,
      newPassword: newPassword,
      cancelToken: cancelToken,
    );
  }
}

