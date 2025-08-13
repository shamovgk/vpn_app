// lib/core/extensions/date_time_ext.dart
import 'package:intl/intl.dart';

extension DateTimeParsingX on String? {
  /// Преобразует ISO8601 (UTC) строку в локальную дату по шаблону.
  /// Возвращает '' если парсинг не удался.
  String toLocalDate({String pattern = 'dd.MM.yyyy'}) {
    final s = this;
    if (s == null) return '';
    final dt = DateTime.tryParse(s);
    if (dt == null) return '';
    return DateFormat(pattern).format(dt.toLocal());
  }

  String toLocalDateTime({String pattern = 'dd.MM.yyyy HH:mm'}) {
    return toLocalDate(pattern: pattern);
  }
}

