// lib/features/payments/models/dto/payment_dto.dart
import '../domain/payment.dart';
import '../domain/payment_method.dart';
import '../domain/payment_status.dart';

class PaymentInitDto {
  final String id;
  final String confirmationUrl;
  final PaymentMethod? method;
  final double? amount;

  PaymentInitDto({
    required this.id,
    required this.confirmationUrl,
    this.method,
    this.amount,
  });

  factory PaymentInitDto.fromMap(Map<String, dynamic> map) {
    final pid = map['paymentId'] as String?;
    final url = map['confirmationUrl'] as String?;
    if (pid == null || url == null) {
      throw const FormatException('Invalid Payment init json');
    }
    final rawMethod = map['method'] as String?;
    final amount = (map['amount'] as num?)?.toDouble();

    return PaymentInitDto(
      id: pid,
      confirmationUrl: url,
      method: _methodFromRawOrNull(rawMethod),
      amount: amount,
    );
  }

  Payment toDomain() => Payment(
        id: id,
        status: PaymentStatus.pending,
        confirmationUrl: confirmationUrl,
        method: method,
        amount: amount,
      );
}

PaymentMethod? _methodFromRawOrNull(String? raw) {
  switch (raw) {
    case 'bank_card':
      return PaymentMethod.bankCard;
    case 'sbp':
      return PaymentMethod.sbp;
    case 'sberbank':
      return PaymentMethod.sberpay;
    default:
      return null;
  }
}