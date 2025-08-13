// lib/features/payments/mappers/payment_mapper.dart
import '../models/domain/payment.dart';
import '../models/domain/payment_status.dart';
import '../models/dto/payment_dto.dart';

Payment paymentFromInitMap(Map<String, dynamic> map) =>
    PaymentInitDto.fromMap(map).toDomain();

Payment withStatus(Payment payment, PaymentStatus status) =>
    payment.copyWith(status: status);
