// lib/core/api/interceptors/logging_interceptor.dart
import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  final bool enabled;
  const LoggingInterceptor({this.enabled = kDebugMode});

  String _redactHeaders(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy['Authorization'] != null) copy['Authorization'] = '***';
    if (copy['Idempotency-Key'] != null) {
      final val = copy['Idempotency-Key'].toString();
      copy['Idempotency-Key'] = val.length <= 8 ? '***' : '${val.substring(0,4)}***${val.substring(val.length-4)}';
    }
    return copy.toString();
  }

  String _reqId(Map<String, dynamic> headers) {
    final v = headers['X-Request-Id'] ?? headers['x-request-id'];
    return v?.toString() ?? '-';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      final rid = _reqId(options.headers);
      dev.log(
        '[HTTP][$rid] → ${options.method} ${options.baseUrl}${options.path} '
        'query=${options.queryParameters} '
        'headers=${_redactHeaders(options.headers)} '
        'body=${_short(options.data)}',
        name: 'DIO',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      final req = response.requestOptions;
      final rid = _reqId(req.headers);
      dev.log(
        '[HTTP][$rid] ← ${response.statusCode} ${req.method} '
        '${req.baseUrl}${req.path} '
        'body=${_short(response.data)}',
        name: 'DIO',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      final req = err.requestOptions;
      final rid = _reqId(req.headers);
      dev.log(
        '[HTTP][$rid] ✕ ${err.response?.statusCode} ${req.method} '
        '${req.baseUrl}${req.path} '
        'reason=${err.message}',
        name: 'DIO',
        error: err,
        stackTrace: err.stackTrace,
      );
    }
    handler.next(err);
  }

  String _short(Object? data) {
    final s = data?.toString() ?? '';
    const max = 600;
    return s.length <= max ? s : '${s.substring(0, max)}…(${s.length} chars)';
  }
}