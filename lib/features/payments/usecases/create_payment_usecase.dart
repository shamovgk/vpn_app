// lib/features/payments/usecases/create_payment_usecase.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain/payment.dart';
import '../models/domain/payment_method.dart';
import '../providers/payment_providers.dart';

typedef CreatePayment = Future<Payment> Function({
  required double amount,
  required PaymentMethod method,
  CancelToken? cancelToken,
});

final createPaymentUseCaseProvider = Provider<CreatePayment>((ref) {
  final repo = ref.watch(paymentsRepositoryProvider);
  return ({required double amount, required PaymentMethod method, CancelToken? cancelToken}) {
    return repo.create(amount: amount, method: method, cancelToken: cancelToken);
  };
});