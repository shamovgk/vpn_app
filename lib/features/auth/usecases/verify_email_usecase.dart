// lib/features/auth/usecases/verify_email_usecase.dart
import 'package:dio/dio.dart';
import '../repositories/auth_repository.dart';

class VerifyEmailUseCase {
  final AuthRepository repo;
  VerifyEmailUseCase(this.repo);

  Future<void> call(String username, String email, String verificationCode, {CancelToken? cancelToken}) {
    return repo.verifyEmail(
      username: username,
      email: email,
      verificationCode: verificationCode,
      cancelToken: cancelToken,
    );
  }
}

