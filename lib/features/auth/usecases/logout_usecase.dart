// lib/features/auth/usecases/logout_usecase.dart
import 'package:dio/dio.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repo;
  LogoutUseCase(this.repo);

  Future<void> call({CancelToken? cancelToken}) => repo.logout(cancelToken: cancelToken);
}

