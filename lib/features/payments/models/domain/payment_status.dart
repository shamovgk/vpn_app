// lib/features/payments/models/domain/payment_status.dart
enum PaymentStatus {
  pending,
  succeeded,
  canceled,
  waitingForCapture,
  failed,
}

PaymentStatus parsePaymentStatus(String raw) {
  switch (raw) {
    case 'pending':
      return PaymentStatus.pending;
    case 'succeeded':
      return PaymentStatus.succeeded;
    case 'canceled':
      return PaymentStatus.canceled;
    case 'waiting_for_capture':
      return PaymentStatus.waitingForCapture;
    default:
      return PaymentStatus.failed;
  }
}