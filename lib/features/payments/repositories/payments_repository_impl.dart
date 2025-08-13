// lib/features/payments/repositories/payments_repository_impl.dart
import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:vpn_app/core/api/api_service.dart';
import 'package:vpn_app/core/cache/memory_cache.dart';
import 'package:vpn_app/core/errors/error_mapper.dart';
import 'package:vpn_app/features/payments/mappers/payment_mapper.dart';
import '../models/domain/payment.dart';
import '../models/domain/payment_method.dart';
import '../models/domain/payment_status.dart';

import 'payments_repository.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  PaymentsRepositoryImpl(this.api, {this.statusTtl = const Duration(seconds: 45)});

  final ApiService api;
  final Duration statusTtl;

  static const _createPath = '/pay';
  static String _reconcilePath(String id) => '/pay/$id/reconcile';

  final Map<String, MemoryCache<PaymentStatus>> _statusCache = {};

  @override
  Future<Payment> create({
    required double amount,
    required PaymentMethod method,
    CancelToken? cancelToken,
  }) async {
    try {
      final idempotencyKey = _genIdempotencyKey();
      final res = await api.post(
        _createPath,
        data: {'amount': amount, 'method': method.serverValue},
        options: Options(extra: {'idempotencyKey': idempotencyKey}),
        cancelToken: cancelToken,
      );

      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) throwFromResponse(res);

      final data = (res.data is Map)
          ? (res.data as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      return paymentFromInitMap(data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<PaymentStatus> getStatus(String paymentId, {CancelToken? cancelToken}) async {
    final cache = _statusCache.putIfAbsent(paymentId, () => MemoryCache<PaymentStatus>());
    if (cache.value != null && !cache.isStale(statusTtl)) {
      return cache.value!;
    }
    final st = await _fetchStatus(paymentId, cancelToken: cancelToken);
    cache.set(st);
    return st;
  }

  @override
  Stream<PaymentStatus> pollStatus(String paymentId, {CancelToken? cancelToken}) async* {
    int attempts = 0;
    while (attempts < 90) {
      if (cancelToken?.isCancelled == true) return;
      attempts++;
      try {
        final st = await _fetchStatus(paymentId, cancelToken: cancelToken);
        _statusCache.putIfAbsent(paymentId, () => MemoryCache<PaymentStatus>()).set(st);
        yield st;
        if (st == PaymentStatus.succeeded || st == PaymentStatus.canceled) return;
      } catch (_) {
        // кратковременные ошибки игнорим
      }
      for (int i = 0; i < 20; i++) {
        if (cancelToken?.isCancelled == true) return;
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    yield PaymentStatus.failed;
  }

  Future<PaymentStatus> _fetchStatus(String paymentId, {CancelToken? cancelToken}) async {
    try {
      final res = await api.post(_reconcilePath(paymentId), data: const {}, cancelToken: cancelToken);
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) throwFromResponse(res);

      final data = (res.data is Map)
          ? (res.data as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final raw = data['status'] as String?;
      if (raw == null) throw const FormatException('Статус не получен');
      return parsePaymentStatus(raw);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  String _genIdempotencyKey() {
    final r = Random();
    const hex = '0123456789abcdef';
    return List.generate(32, (_) => hex[r.nextInt(16)]).join();
  }
}
