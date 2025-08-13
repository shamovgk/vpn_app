// lib/core/extensions/string_ext.dart
extension StringValidatorsX on String? {
  String? validateUsername({int min = 3}) {
    final v = this?.trim() ?? '';
    if (v.isEmpty) return 'Введите логин';
    if (v.length < min) return 'Минимум $min символов';
    return null;
  }

  String? validateEmail() {
    final v = this?.trim() ?? '';
    if (v.isEmpty) return 'Введите email';
    final rx = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!rx.hasMatch(v)) return 'Неверный формат email';
    return null;
  }

  String? validatePassword({int min = 6}) {
    final v = this ?? '';
    if (v.isEmpty) return 'Введите пароль';
    if (v.length < min) return 'Минимум $min символов';
    return null;
  }

  String? validateCode({int min = 4}) {
    final v = this?.trim() ?? '';
    if (v.isEmpty) return 'Введите код';
    if (v.length < min) return 'Слишком короткий код';
    return null;
  }

  String? validateCodeExact({int length = 6}) {
    final v = this?.trim() ?? '';
    if (v.isEmpty) return 'Введите код';
    if (v.length != length) return 'Код должен содержать $length цифр';
    return null;
  }
}
