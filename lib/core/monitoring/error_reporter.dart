// lib/core/monitoring/error_reporter.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// Единый интерфейс (можно будет подменить на Sentry/Crashlytics без правок по коду)
abstract class ErrorReporter {
  Future<void> captureException(
    Object error,
    StackTrace stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? extras,
  });
}

/// Дефолт: логгер
class LogOnlyErrorReporter implements ErrorReporter {
  final Logger _log = Logger();
  @override
  Future<void> captureException(
    Object error,
    StackTrace stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? extras,
  }) async {
    _log.e('[ErrorReporter] $error', error: error, stackTrace: stackTrace);
    if (extras != null && extras.isNotEmpty) {
      _log.w('[ErrorReporter extras] $extras');
    }
    if (tags != null && tags.isNotEmpty) {
      _log.w('[ErrorReporter tags] $tags');
    }
  }
}

/// Устанавливает глобальные обработчики ошибок на старте приложения.
void installGlobalErrorHandlers(ErrorReporter reporter) {
  FlutterError.onError = (details) async {
    // Перехватываем Flutter ошибки
    await reporter.captureException(details.exception, details.stack ?? StackTrace.current, tags: {
      'zone': 'FlutterError',
    });
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    // Перехватываем uncaught native/dart async
    unawaited(reporter.captureException(error, stack, tags: {'zone': 'PlatformDispatcher'}));
    return true; // поглощаем
  };
}
