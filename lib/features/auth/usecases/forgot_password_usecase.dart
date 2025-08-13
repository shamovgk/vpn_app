// lib/features/auth/usecases/forgot_password_usecase.dart
import 'package:dio/dio.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repo;
  ForgotPasswordUseCase(this.repo);

  Future<void> call(String username, {CancelToken? cancelToken}) => repo.forgotPassword(username, cancelToken: cancelToken);
}

