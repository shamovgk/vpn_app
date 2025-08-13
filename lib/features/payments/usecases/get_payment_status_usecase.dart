// lib/features/payments/usecases/get_payment_status_usecase.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain/payment_status.dart';
import '../providers/payment_providers.dart';

typedef GetPaymentStatus = Future<PaymentStatus> Function(String paymentId, {CancelToken? cancelToken});

final getPaymentStatusUseCaseProvider = Provider<GetPaymentStatus>((ref) {
  final repo = ref.watch(paymentsRepositoryProvider);
  return (paymentId, {CancelToken? cancelToken}) => repo.getStatus(paymentId, cancelToken: cancelToken);
});