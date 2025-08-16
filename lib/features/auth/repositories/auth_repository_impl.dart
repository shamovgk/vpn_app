// lib/features/auth/repositories/auth_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import '../../../core/errors/error_mapper.dart';
import '../models/dto/user_dto.dart';
import '../mappers/user_mapper.dart';
import '../models/domain/user.dart';
import '../models/domain/login_result.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  return AuthRepositoryImpl(api);
});

class AuthRepositoryImpl implements AuthRepository {
  final ApiService api;
  AuthRepositoryImpl(this.api);

  @override
  Future<LoginResult> login({required String username, required String password, CancelToken? cancelToken}) async {
    final res = await api.post('/auth/login', data: {'username': username, 'password': password}, cancelToken: cancelToken);
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      final data = (res.data as Map).cast<String, dynamic>();
      final token = data['token'] as String?;
      final userMap = (data['user'] as Map?)?.cast<String, dynamic>();
      if (token == null || userMap == null) {
        throwFromResponse(res);
      }
      final dto = UserDto.fromJson(userMap);
      final user = userFromDto(dto);
      return LoginResult(token: token, user: user);
    }
    throwFromResponse(res);
  }

  @override
  Future<void> register({required String username, required String email, required String password, CancelToken? cancelToken}) async {
    final res = await api.post('/auth/register', data: {'username': username, 'email': email, 'password': password}, cancelToken: cancelToken);
    final code = res.statusCode ?? 0;
    if (code < 200 || code >= 300) throwFromResponse(res);
  }

  @override
  Future<void> verifyEmail({required String username, required String email, required String verificationCode, CancelToken? cancelToken}) async {
    final res = await api.post('/auth/verify-email',
      data: {'username': username, 'email': email, 'verificationCode': verificationCode},
      cancelToken: cancelToken,
    );
    final code = res.statusCode ?? 0;
    if (code < 200 || code >= 300) throwFromResponse(res);
  }

  @override
  Future<void> logout({CancelToken? cancelToken}) async {
    final res = await api.post('/auth/logout', data: {}, cancelToken: cancelToken);
    final code = res.statusCode ?? 0;
    if (code < 200 || code >= 300) throwFromResponse(res);
  }

  @override
  Future<User> validateToken({CancelToken? cancelToken}) async {
    final res = await api.get('/auth/validate-token', cancelToken: cancelToken);
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      final data = (res.data is Map) ? (res.data as Map).cast<String, dynamic>() : <String, dynamic>{};
      final dto = UserDto.fromJson(data);
      return userFromDto(dto);
    }
    throwFromResponse(res);
  }

  @override
  Future<void> forgotPassword(String username, {CancelToken? cancelToken}) async {
    final res = await api.post('/auth/forgot-password', data: {'username': username}, cancelToken: cancelToken);
    final code = res.statusCode ?? 0;
    if (code < 200 || code >= 300) throwFromResponse(res);
  }

  @override
  Future<void> resetPassword({required String username, required String resetCode, required String newPassword, CancelToken? cancelToken}) async {
    final res = await api.post('/auth/reset-password',
      data: {'username': username, 'resetCode': resetCode, 'newPassword': newPassword},
      cancelToken: cancelToken,
    );
    final code = res.statusCode ?? 0;
    if (code < 200 || code >= 300) throwFromResponse(res);
  }
}


