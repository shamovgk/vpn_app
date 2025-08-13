// lib/features/payments/repositories/payments_repository.dart
import 'package:dio/dio.dart';
import '../models/domain/payment.dart';
import '../models/domain/payment_status.dart';
import '../models/domain/payment_method.dart';

abstract class PaymentsRepository {
  Future<Payment> create({
    required double amount,
    required PaymentMethod method,
    CancelToken? cancelToken,
  });

  Future<PaymentStatus> getStatus(String paymentId, {CancelToken? cancelToken});
  Stream<PaymentStatus> pollStatus(String paymentId, {CancelToken? cancelToken});
}
