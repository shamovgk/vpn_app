// lib/features/payments/providers/payment_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import '../repositories/payments_repository.dart';
import '../repositories/payments_repository_impl.dart';

export 'payment_controller.dart';
export 'package:vpn_app/features/payments/usecases/create_payment_usecase.dart';
export 'package:vpn_app/features/payments/usecases/get_payment_status_usecase.dart';
export 'package:vpn_app/features/payments/usecases/poll_payment_status_usecase.dart';

final paymentStatusTtlProvider = Provider<Duration>((_) => const Duration(seconds: 45), name: 'paymentStatusTtl');

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepositoryImpl(
    ref.read(apiServiceProvider),
    statusTtl: ref.read(paymentStatusTtlProvider),
  );
}, name: 'paymentsRepository');

