// lib/features/payments/providers/payment_controller.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/ui_error.dart';
import '../models/domain/payment.dart';
import '../models/domain/payment_method.dart';
import '../models/domain/payment_status.dart';
import '../models/payment_state.dart';
import '../usecases/create_payment_usecase.dart';
import '../usecases/get_payment_status_usecase.dart';
import '../usecases/poll_payment_status_usecase.dart';

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentState>((ref) {
  final ctrl = PaymentController(
    createPayment: ref.watch(createPaymentUseCaseProvider),
    getStatus: ref.watch(getPaymentStatusUseCaseProvider),
    pollStatus: ref.watch(pollPaymentStatusUseCaseProvider),
  );
  ref.onDispose(ctrl.dispose);
  return ctrl;
}, name: 'paymentController');

class PaymentController extends StateNotifier<PaymentState> {
  PaymentController({
    required this.createPayment,
    required this.getStatus,
    required this.pollStatus,
  }) : super(const PaymentIdle());

  final CreatePayment createPayment;
  final GetPaymentStatus getStatus;
  final PollPaymentStatus pollStatus;

  StreamSubscription<PaymentStatus>? _sub;
  CancelToken? _ct;

  CancelToken _replaceToken() {
    _ct?.cancel('payment:replaced');
    final t = CancelToken();
    _ct = t;
    return t;
  }

  void _cancel() {
    _sub?.cancel();
    _sub = null;
    if (_ct != null && !_ct!.isCancelled) _ct!.cancel('payment:cancel');
    _ct = null;
  }

  Future<void> startPayment({
    required PaymentMethod method,
    double amount = 1.0,
  }) async {
    _cancel();
    state = const PaymentLoading();
    final ct = _replaceToken();
    try {
      final created =
          await createPayment(amount: amount, method: method, cancelToken: ct);
      state = PaymentReady(created);

      _sub = pollStatus(created.id, cancelToken: ct).listen((st) {
        final current = (state is PaymentPolling || state is PaymentReady)
            ? (state is PaymentPolling
                ? (state as PaymentPolling).payment
                : (state as PaymentReady).payment)
            : created;

        final updated = current.copyWith(status: st);

        switch (st) {
          case PaymentStatus.succeeded:
            state = PaymentSucceeded(updated);
            _cancel();
            break;
          case PaymentStatus.canceled:
            state = PaymentCanceled(updated);
            _cancel();
            break;
          default:
            state = PaymentPolling(updated);
        }
      });
    } catch (e) {
      if (!ct.isCancelled) state = PaymentFailed(presentableError(e));
    }
  }

  Future<void> checkPaymentStatus(String paymentId) async {
    final ct = _replaceToken();
    try {
      final st = await getStatus(paymentId, cancelToken: ct);

      Payment base = Payment(id: paymentId, status: st);
      final s = state;
      if (s is PaymentReady && s.payment.id == paymentId) {
        base = s.payment.copyWith(status: st);
      } else if (s is PaymentPolling && s.payment.id == paymentId) {
        base = s.payment.copyWith(status: st);
      }

      switch (st) {
        case PaymentStatus.succeeded:
          state = PaymentSucceeded(base);
          break;
        case PaymentStatus.canceled:
          state = PaymentCanceled(base);
          break;
        default:
          state = PaymentPolling(base);
      }
    } catch (e) {
      if (!ct.isCancelled) {
        state = PaymentFailed(presentableError(e), paymentId: paymentId);
      }
    }
  }

  void reset() {
    _cancel();
    state = const PaymentIdle();
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}