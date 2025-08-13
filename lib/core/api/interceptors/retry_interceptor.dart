// lib/core/api/interceptors/retry_interceptor.dart
import 'dart:math';
import 'package:dio/dio.dart';

typedef BoolFn = bool Function();
typedef WaitFn = Future<void> Function();

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;
  final BoolFn? isOnline;
  final WaitFn? waitUntilOnline;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 300),
    this.isOnline,
    this.waitUntilOnline,
  });

  bool _isIdempotent(RequestOptions r) {
    final m = r.method.toUpperCase();
    return m == 'GET' || m == 'HEAD' || m == 'OPTIONS';
  }

  bool _isTransient(DioException err) {
    final res = err.response;
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.connectionError ||
           err.type == DioExceptionType.receiveTimeout ||
           (res != null && [502, 503, 504].contains(res.statusCode));
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    final attempt = (req.extra['retry_attempt'] as int?) ?? 0;

    if (!(_isIdempotent(req) && _isTransient(err) && attempt < maxRetries)) {
      return handler.next(err);
    }

    // офлайн — ждём восстановление сети
    if (isOnline != null && waitUntilOnline != null && !isOnline!()) {
      await waitUntilOnline!();
    }

    final jitter = Random().nextInt(baseDelay.inMilliseconds + 1);
    final backoffMs = baseDelay.inMilliseconds * (1 << attempt) + jitter;
    await Future.delayed(Duration(milliseconds: backoffMs));

    try {
      final res = await dio.fetch(req.copyWith(
        extra: {...req.extra, 'retry_attempt': attempt + 1},
      ));
      return handler.resolve(res);
    } catch (e) {
      return handler.next(e is DioException ? e : err);
    }
  }
}