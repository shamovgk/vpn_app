// lib/core/errors/exceptions.dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  const ApiException(this.message, [this.statusCode, this.code]);
  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(String message) : super(message, 401, 'UNAUTHORIZED');
}

