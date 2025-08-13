// lib/features/payments/models/domain/payment.dart
import 'payment_method.dart';
import 'payment_status.dart';

class Payment {
  final String id;
  final PaymentStatus status;
  final String? confirmationUrl;
  final PaymentMethod? method;
  final double? amount;

  const Payment({
    required this.id,
    required this.status,
    this.confirmationUrl,
    this.method,
    this.amount,
  });

  Payment copyWith({
    String? id,
    PaymentStatus? status,
    String? confirmationUrl,
    PaymentMethod? method,
    double? amount,
  }) {
    return Payment(
      id: id ?? this.id,
      status: status ?? this.status,
      confirmationUrl: confirmationUrl ?? this.confirmationUrl,
      method: method ?? this.method,
      amount: amount ?? this.amount,
    );
  }

  @override
  String toString() =>
      'Payment(id: $id, status: $status, confirmationUrl: $confirmationUrl, method: $method, amount: $amount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          confirmationUrl == other.confirmationUrl &&
          method == other.method &&
          amount == other.amount;

  @override
  int get hashCode => Object.hash(id, status, confirmationUrl, method, amount);
}