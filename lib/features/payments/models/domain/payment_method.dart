// lib/features/payments/models/domain/payment_method.dart
enum PaymentMethod { bankCard, sbp, sberpay }

extension PaymentMethodApiX on PaymentMethod {
  String get serverValue {
    switch (this) {
      case PaymentMethod.bankCard:
        return 'bank_card';
      case PaymentMethod.sbp:
        return 'sbp';
      case PaymentMethod.sberpay:
        return 'sberbank';
    }
  }
}