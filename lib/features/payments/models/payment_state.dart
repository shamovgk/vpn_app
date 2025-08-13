// lib/features/payments/models/payment_state.dart
import 'domain/payment.dart';

sealed class PaymentState {
  const PaymentState();
}

class PaymentIdle extends PaymentState {
  const PaymentIdle();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentReady extends PaymentState {
  final Payment payment;
  const PaymentReady(this.payment);
}

class PaymentPolling extends PaymentState {
  final Payment payment;
  const PaymentPolling(this.payment);
}

class PaymentSucceeded extends PaymentState {
  final Payment payment;
  const PaymentSucceeded(this.payment);
}

class PaymentCanceled extends PaymentState {
  final Payment payment;
  const PaymentCanceled(this.payment);
}

class PaymentFailed extends PaymentState {
  final String message;
  final String? paymentId;
  const PaymentFailed(this.message, {this.paymentId});
}