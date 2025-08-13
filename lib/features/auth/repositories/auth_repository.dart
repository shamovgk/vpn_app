// lib/features/auth/repositories/auth_repository.dart
import 'package:dio/dio.dart';
import '../models/domain/user.dart';
import '../models/domain/login_result.dart';

abstract class AuthRepository {
  Future<LoginResult> login({required String username, required String password, CancelToken? cancelToken});
  Future<void> register({required String username, required String email, required String password, CancelToken? cancelToken});
  Future<void> verifyEmail({required String username, required String email, required String verificationCode, CancelToken? cancelToken});
  Future<void> logout({CancelToken? cancelToken});
  Future<User> validateToken({CancelToken? cancelToken});
  Future<void> forgotPassword(String username, {CancelToken? cancelToken});
  Future<void> resetPassword({required String username, required String resetCode, required String newPassword, CancelToken? cancelToken});
}


