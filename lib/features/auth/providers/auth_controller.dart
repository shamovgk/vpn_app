// lib/features/auth/providers/auth_controller.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/cache/memory_cache.dart';
import 'package:vpn_app/core/models/feature_state.dart';
import 'package:vpn_app/features/subscription/providers/subscription_controller.dart';
import 'package:vpn_app/features/vpn/providers/vpn_controller.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/storage/secure_storage.dart';
import '../../devices/providers/device_providers.dart';
import '../models/domain/user.dart';
import '../repositories/auth_repository_impl.dart';
import '../usecases/login_usecase.dart';
import '../usecases/register_usecase.dart';
import '../usecases/verify_email_usecase.dart';
import '../usecases/validate_token_usecase.dart';
import '../usecases/logout_usecase.dart';
import '../usecases/forgot_password_usecase.dart';
import '../usecases/reset_password_usecase.dart';
import 'auth_providers.dart';

typedef AuthState = FeatureState<User>;

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final repo = ref.read(authRepositoryProvider);
    return AuthController(ref, repo);
  },
  name: 'authController',
);

class AuthController extends StateNotifier<AuthState> {
  final MemoryCache<User> _userCache = MemoryCache<User>();
  final Ref ref;
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final VerifyEmailUseCase _verifyEmail;
  final ValidateTokenUseCase _validateToken;
  final LogoutUseCase _logout;
  final ForgotPasswordUseCase _forgotPassword;
  final ResetPasswordUseCase _resetPassword;

  CancelToken? _ct;

  AuthController(this.ref, repo)
      : _login = LoginUseCase(repo),
        _register = RegisterUseCase(repo),
        _verifyEmail = VerifyEmailUseCase(repo),
        _validateToken = ValidateTokenUseCase(repo),
        _logout = LogoutUseCase(repo),
        _forgotPassword = ForgotPasswordUseCase(repo),
        _resetPassword = ResetPasswordUseCase(repo),
        super(const FeatureIdle()) {
    ref.onDispose(_cancelActive);
    _bootstrap();
  }

  CancelToken _replaceToken() {
    _ct?.cancel('auth:replaced');
    final t = CancelToken();
    _ct = t;
    return t;
  }

  void _cancelActive() {
    final t = _ct;
    if (t != null && !t.isCancelled) {
      t.cancel('auth:dispose');
    }
    _ct = null;
  }

  Future<void> _bootstrap() async {
    final token = await AppSecureStorage.readToken();
    ref.read(tokenProvider.notifier).state = token;

    if (token != null) {
      unawaited(ref.read(subscriptionControllerProvider.notifier).fetch());
    }

    final cached = _userCache.value;
    if (token != null && cached != null) {
      state = FeatureReady<User>(cached);
      unawaited(_softValidate());
    } else if (token != null) {
      await validateToken();
    }
  }

  Future<void> _softValidate() async {
    try {
      final user = await _validateToken(cancelToken: _replaceToken());
      _userCache.set(user);
      state = FeatureReady<User>(user);
      await ref.read(subscriptionControllerProvider.notifier).fetch();
      unawaited(ref.read(deviceControllerProvider.notifier).touchLastSeen());
    } catch (_) {
      // шум не нужен
    }
  }

  bool get isLoading => state.isLoading;
  String? get errorMessage => state.errorMessage;
  bool get isLoggedIn => state is FeatureReady<User>;

  Future<void> login(String username, String password) async {
    state = const FeatureLoading();
    final ct = _replaceToken();
    try {
      final res = await _login(username, password, cancelToken: ct);
      ref.read(tokenProvider.notifier).state = res.token;
      await AppSecureStorage.saveToken(res.token);

      _userCache.set(res.user);
      state = FeatureReady<User>(res.user);

      await ref.read(subscriptionControllerProvider.notifier).fetch();
      await ref.read(deviceControllerProvider.notifier).addCurrent();
      unawaited(ref.read(deviceControllerProvider.notifier).load());
    } on ApiException catch (e) {
      if (!ct.isCancelled) state = FeatureError<User>(e.message);
    } catch (_) {
      if (!ct.isCancelled) state = const FeatureError<User>('Неизвестная ошибка');
    }
  }

  Future<void> register(String username, String email, String password) async {
    state = const FeatureLoading();
    final ct = _replaceToken();
    try {
      await _register(username, email, password, cancelToken: ct);
      state = const FeatureIdle();
    } on ApiException catch (e) {
      if (!ct.isCancelled) state = FeatureError<User>(e.message);
    }
  }

  Future<void> verifyEmail(String username, String email, String code) async {
    state = const FeatureLoading();
    final ct = _replaceToken();
    try {
      await _verifyEmail(username, email, code, cancelToken: ct);
      state = const FeatureIdle();
    } on ApiException catch (e) {
      if (!ct.isCancelled) state = FeatureError<User>(e.message);
    }
  }

  Future<void> validateToken() async {
    state = const FeatureLoading();
    final ct = _replaceToken();
    try {
      final user = await _validateToken(cancelToken: ct);
      _userCache.set(user);
      state = FeatureReady<User>(user);
      await ref.read(subscriptionControllerProvider.notifier).fetch();
      unawaited(ref.read(deviceControllerProvider.notifier).touchLastSeen());
    } on UnauthorizedException {
      await logout(silent: true);
      state = const FeatureIdle();
    } on ApiException catch (e) {
      if (!ct.isCancelled) state = FeatureError<User>(e.message);
    }
  }

  Future<void> logout({bool silent = false}) async {
    if (!silent) state = const FeatureLoading();
    final ct = _replaceToken();
    try {
      await ref.read(vpnControllerProvider.notifier).disconnectPressed();
      await _logout(cancelToken: ct);
    } catch (_) {}
    _userCache.clear();
    ref.read(tokenProvider.notifier).state = null;
    await AppSecureStorage.clearToken();

    ref.invalidate(subscriptionControllerProvider);
    ref.invalidate(deviceControllerProvider);

    state = const FeatureIdle();
  }

  Future<void> forgotPassword(String username) async {
    state = const FeatureLoading();
    final ct = _replaceToken();
    try {
      await _forgotPassword(username, cancelToken: ct);
      state = const FeatureIdle();
    } on ApiException catch (e) {
      if (!ct.isCancelled) state = FeatureError<User>(e.message);
    }
  }

  Future<void> resetPassword(String username, String resetCode, String newPassword) async {
    state = const FeatureLoading();
    final ct = _replaceToken();
    try {
      await _resetPassword(username, resetCode, newPassword, cancelToken: ct);
      state = const FeatureIdle();
    } on ApiException catch (e) {
      if (!ct.isCancelled) state = FeatureError<User>(e.message);
    }
  }
}


