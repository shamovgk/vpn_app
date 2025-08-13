// lib/features/payments/usecases/poll_payment_status_usecase.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain/payment_status.dart';
import '../providers/payment_providers.dart';

typedef PollPaymentStatus = Stream<PaymentStatus> Function(String paymentId, {CancelToken? cancelToken});

final pollPaymentStatusUseCaseProvider = Provider<PollPaymentStatus>((ref) {
  final repo = ref.watch(paymentsRepositoryProvider);
  return (paymentId, {CancelToken? cancelToken}) => repo.pollStatus(paymentId, cancelToken: cancelToken);
});