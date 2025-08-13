// lib/core/api/http_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../network/connectivity_provider.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/headers_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

final appConfigProvider = Provider<AppConfig>((_) => AppConfig.fromEnv(), name: 'appConfig');

final httpClientProvider = Provider<Dio>((ref) {
  ref.watch(swrRefreshOnReconnectProvider);

  final cfg = ref.watch(appConfigProvider);

  final dio = Dio(BaseOptions(
    baseUrl: cfg.baseUrl,
    connectTimeout: cfg.connectTimeout,
    receiveTimeout: cfg.receiveTimeout,
    headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
    validateStatus: (_) => true,
  ));

  final netPolicy = ref.read(networkPolicyProvider);

  dio.interceptors.addAll([
    HeadersInterceptor(),
    AuthInterceptor(ref),
    RetryInterceptor(
      dio: dio,
      isOnline: () => netPolicy.isOnline,
      waitUntilOnline: () => netPolicy.waitUntilOnline(),
    ),
    LoggingInterceptor(enabled: kDebugMode),
  ]);

  ref.onDispose(() => dio.close(force: true));
  return dio;
}, name: 'httpClient');
