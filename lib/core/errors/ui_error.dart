// lib/core/errors/ui_error.dart
import 'exceptions.dart';

String presentableError(Object e) {
  if (e is UnauthorizedException) return 'Неавторизовано. Войдите заново.';
  if (e is ApiException) {
    final code = e.code != null ? ' [${e.code}]' : '';
    final sc   = e.statusCode != null ? ' (код: ${e.statusCode})' : '';
    return '${e.message}$code$sc';
  }
  return e.toString();
}

