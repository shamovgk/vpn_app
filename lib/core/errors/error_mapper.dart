// lib/core/errors/error_mapper.dart
import 'package:dio/dio.dart';
import 'exceptions.dart';

Never throwFromResponse(Response res) {
  final status = res.statusCode ?? 0;
  String? code;
  String? msg;

  final data = res.data;
  if (data is Map) {
    if (data['error'] is Map) {
      final err = data['error'] as Map;
      code = err['code']?.toString();
      msg  = err['message']?.toString();
    } else if (data['error'] != null) {
      msg = data['error'].toString();
    } else if (data['message'] != null) {
      msg = data['message'].toString();
    }
  }

  msg ??= 'Ошибка: $status';
  if (status == 401) throw UnauthorizedException(msg);
  throw ApiException(msg, status, code);
}

ApiException mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      return const ApiException('Проблема с сетью. Проверьте подключение.');
    case DioExceptionType.badCertificate:
      return const ApiException('Проблема с сертификатом соединения.');
    case DioExceptionType.cancel:
      return const ApiException('Запрос отменён пользователем.');
    case DioExceptionType.badResponse:
      return ApiException(
        e.message ?? 'Ошибка ответа сервера',
        e.response?.statusCode,
      );
    case DioExceptionType.unknown:
    return ApiException(e.message ?? 'Неизвестная ошибка', e.response?.statusCode);
  }
}

