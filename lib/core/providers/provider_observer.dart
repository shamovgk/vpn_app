// lib/core/providers/provider_observer.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../monitoring/error_reporter.dart';

class AppProviderObserver extends ProviderObserver {
  AppProviderObserver({
    ErrorReporter? reporter,
    this.logTransitions = true,
    this.logAddDispose = false,
    this.maxValueLength = 800,
    Set<Pattern>? maskedProviderNamePatterns,
    Set<Pattern>? maskedFieldNamePatterns,
  })  : _reporter = reporter ?? LogOnlyErrorReporter(),
        _log = Logger(),
        _maskedProviderNamePatterns = maskedProviderNamePatterns ??
            {
              RegExp(r'token', caseSensitive: false),
              RegExp(r'password', caseSensitive: false),
              RegExp(r'secret', caseSensitive: false),
              RegExp(r'auth', caseSensitive: false),
            },
        _maskedFieldNamePatterns = maskedFieldNamePatterns ??
            {
              RegExp(r'token', caseSensitive: false),
              RegExp(r'password', caseSensitive: false),
              RegExp(r'secret', caseSensitive: false),
            };

  final ErrorReporter _reporter;
  final Logger _log;

  final bool logTransitions;
  final bool logAddDispose;
  final int maxValueLength;

  final Set<Pattern> _maskedProviderNamePatterns;
  final Set<Pattern> _maskedFieldNamePatterns;

  @override
  void didAddProvider(
    ProviderBase provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (!logAddDispose) return;
    _log.i('(+)\t${_pName(provider)} = ${_fmtValue(provider, value)}');
  }

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (!logTransitions) return;
    // Фильтр технических/шумных провайдеров при релизе
    if (kReleaseMode && !_isInteresting(provider)) return;

    final p = _fmtValue(provider, previousValue);
    final n = _fmtValue(provider, newValue);
    _log.d('(~)\t${_pName(provider)}\n  prev: $p\n  next: $n');
  }

  @override
  void didDisposeProvider(ProviderBase provider, ProviderContainer container) {
    if (!logAddDispose) return;
    _log.i('(-)\t${_pName(provider)}');
  }

  @override
  void providerDidFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    _log.e('(!)\t${_pName(provider)} failed: $error', error: error, stackTrace: stackTrace);
    // Отправляем в внешний репортинг
    _reporter.captureException(
      error,
      stackTrace,
      tags: {'provider': _pName(provider)},
    );
  }

  // === helpers ===

  String _pName(ProviderBase p) {
    // Пытаемся использовать provider.name, если задан (в Riverpod 2 можно именовать провайдеры)
    final name = p.name ?? p.runtimeType.toString();
    return name;
  }

  bool _matchAny(String input, Set<Pattern> patterns) {
    for (final pat in patterns) {
      if (pat is RegExp) {
        if (pat.hasMatch(input)) return true;
      } else if (pat is String) {
        if (input.toLowerCase().contains(pat.toLowerCase())) return true;
      }
    }
    return false;
  }

  bool _shouldMaskProvider(ProviderBase p) {
    final name = _pName(p);
    return _matchAny(name, _maskedProviderNamePatterns);
  }

  String _fmtValue(ProviderBase p, Object? v) {
    if (v == null) return 'null';

    // Если провайдер чувствительный — не логируем payload
    if (_shouldMaskProvider(p)) return '<masked>';

    dynamic safe = v;
    // Пробуем сериализовать State классы/DTO/Domain, осторожно маскируем поля
    try {
      safe = _maskObject(v);
    } catch (_) {
      // ignore
    }

    String text;
    try {
      if (safe is String) {
        text = safe;
      } else if (safe is Map || safe is List) {
        text = const JsonEncoder.withIndent('  ').convert(safe);
      } else {
        text = safe.toString();
      }
    } catch (_) {
      text = v.toString();
    }

    if (text.length > maxValueLength) {
      text = '${text.substring(0, maxValueLength)}…<truncated>';
    }
    return text;
  }

  bool _isInteresting(ProviderBase p) {
    final t = p.runtimeType.toString().toLowerCase();
    // Сохраняем важные типы, остальное в релизе игнорим
    return t.contains('statenotifierprovider') ||
        t.contains('futureprovider') ||
        t.contains('streamprovider') ||
        t.contains('stateprovider');
  }

  dynamic _maskObject(Object? v) {
    if (v == null) return null;
    if (v is String) {
      // простая маскировка токенов/JWT
      if (v.contains('.') && v.split('.').length >= 3) return _maskString(v);
      if (v.length > 64) return '${v.substring(0, 6)}***${v.substring(v.length - 4)}';
      return v;
    }
    if (v is Map) {
      return v.map((k, val) {
        final key = k.toString();
        final masked = _matchAny(key, _maskedFieldNamePatterns);
        return MapEntry(key, masked ? '<masked>' : _maskObject(val));
      });
    }
    if (v is Iterable) {
      return v.map(_maskObject).toList();
    }
    // Пытаемся отразить поля data-классов
    try {
      final json = (v as dynamic).toJson?.call();
      if (json is Map) return _maskObject(json);
    } catch (_) {}
    return v;
  }

  String _maskString(String s) {
    if (s.length <= 12) return '***';
    return '${s.substring(0, 4)}***${s.substring(s.length - 4)}';
  }
}
