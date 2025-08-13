// lib/features/auth/usecases/validate_token_usecase.dart
import 'package:dio/dio.dart';
import '../models/domain/user.dart';
import '../repositories/auth_repository.dart';

class ValidateTokenUseCase {
  final AuthRepository repo;
  ValidateTokenUseCase(this.repo);

  Future<User> call({CancelToken? cancelToken}) => repo.validateToken(cancelToken: cancelToken);
}
