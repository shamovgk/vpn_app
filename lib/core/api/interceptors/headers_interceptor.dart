// lib/core/api/interceptors/headers_interceptor.dart
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class HeadersInterceptor extends Interceptor {
  final _uuid = const Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('Accept', () => 'application/json');

    options.headers.putIfAbsent('X-Request-Id', () => _uuid.v4());

    final key = options.extra['idempotencyKey'];
    final method = options.method.toUpperCase();
    final isUnsafe = method == 'POST' || method == 'PUT' || method == 'PATCH' || method == 'DELETE';
    if (isUnsafe && key is String && key.isNotEmpty) {
      options.headers['Idempotency-Key'] = key;
    }

    handler.next(options);
  }
}


