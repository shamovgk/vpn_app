// lib/features/auth/usecases/register_usecase.dart
import 'package:dio/dio.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repo;
  RegisterUseCase(this.repo);

  Future<void> call(String username, String email, String password, {CancelToken? cancelToken}) {
    return repo.register(username: username, email: email, password: password, cancelToken: cancelToken);
  }
}

