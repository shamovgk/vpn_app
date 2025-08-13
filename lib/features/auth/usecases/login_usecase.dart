// lib/features/auth/usecases/login_usecase.dart
import 'package:dio/dio.dart';
import '../models/domain/login_result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repo;
  LoginUseCase(this.repo);
  Future<LoginResult> call(String username, String password, {CancelToken? cancelToken}) {
    return repo.login(username: username, password: password, cancelToken: cancelToken);
  }
}


