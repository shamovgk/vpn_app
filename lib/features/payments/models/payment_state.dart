import 'package:flutter/foundation.dart';

@immutable
class PaymentState {
  final String? paymentUrl;
  final bool isLoading;
  final String? error;

  const PaymentState({
    this.paymentUrl,
    this.isLoading = false,
    this.error,
  });

  PaymentState copyWith({
    String? paymentUrl,
    bool? isLoading,
    String? error,
  }) {
    return PaymentState(
      paymentUrl: paymentUrl ?? this.paymentUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  static const initial = PaymentState();
}
