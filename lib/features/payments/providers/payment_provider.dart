import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_service.dart';
import '../services/payment_service.dart';

// PaymentState - чистый immutable-класс состояния
class PaymentState {
  final bool loading;
  final String? paymentUrl;
  final String? error;

  const PaymentState({
    this.loading = false,
    this.paymentUrl,
    this.error,
  });

  PaymentState copyWith({
    bool? loading,
    String? paymentUrl,
    String? error,
  }) {
    return PaymentState(
      loading: loading ?? this.loading,
      paymentUrl: paymentUrl,
      error: error,
    );
  }
}

// PaymentNotifier - логика работы
class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentService service;

  PaymentNotifier(this.service) : super(const PaymentState());

  Future<void> fetchPaymentUrl(String method) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final url = await service.createPaymentUrl(amount: 150.00, method: method);
      state = PaymentState(loading: false, paymentUrl: url);
    } catch (e) {
      state = PaymentState(loading: false, error: e.toString());
    }
  }

  void reset() {
    state = const PaymentState();
  }
}

// Провайдер для PaymentService
final paymentServiceProvider = Provider<PaymentService>((ref) {
  final api = ref.read(apiServiceProvider);
  return PaymentService(api);
});

// Провайдер для PaymentNotifier
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final service = ref.watch(paymentServiceProvider);
  return PaymentNotifier(service);
});
