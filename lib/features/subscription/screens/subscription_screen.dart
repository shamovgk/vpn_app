// lib/features/subscription/screens/subscription_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vpn_app/core/api/http_client.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/core/extensions/nav_ext.dart';
import 'package:vpn_app/core/extensions/date_time_ext.dart';

import 'package:vpn_app/features/payments/models/domain/payment_status.dart';
import 'package:vpn_app/features/payments/models/payment_state.dart';
import 'package:vpn_app/features/subscription/models/subscription_status.dart';
import 'package:vpn_app/features/subscription/providers/subscription_providers.dart';
import 'package:vpn_app/features/subscription/models/subscription_state.dart';
import 'package:vpn_app/features/subscription/widgets/subscription_confirming_block.dart';
import 'package:vpn_app/ui/widgets/app_custom_appbar.dart';
import 'package:vpn_app/ui/widgets/atoms/primary_button.dart';
import 'package:vpn_app/ui/widgets/themed_scaffold.dart';
import 'package:vpn_app/ui/widgets/app_snackbar.dart';

import 'package:vpn_app/features/payments/providers/payment_providers.dart';
import 'package:vpn_app/features/payments/screens/payment_webview_screen.dart';
import 'package:vpn_app/features/payments/widgets/payment_method_sheet.dart';

import '../widgets/status_card.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isWebViewOpen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(subscriptionControllerProvider.notifier).fetch());
  }

  // ===== Helpers UI =====

  ThemedScaffold _screen(Widget body) =>
      ThemedScaffold(appBar: const AppCustomAppBar(title: 'Подписка'), body: body);

  ({String statusText, String periodText, Color statusColor}) _describeStatus(
    BuildContext context,
    SubscriptionStatus status,
  ) {
    final c = context.colors;
    if (status.isTrial) {
      return (
        statusText: 'Пробный период',
        periodText: 'Доступ до ${status.trialEndDate.toLocalDate()}',
        statusColor: c.info
      );
    }
    if (status.isPaid && status.paidUntil != null) {
      return (
        statusText: 'Подписка активна',
        periodText: 'До ${status.paidUntil!.toLocalDate()}',
        statusColor: c.success
      );
    }
    return (
      statusText: 'Подписка неактивна',
      periodText: 'Нет активной подписки',
      statusColor: c.danger
    );
  }

  Future<void> _onSucceededFlow() async {
    await ref.read(subscriptionControllerProvider.notifier).fetch();
    if (!mounted) return;

    if (_isWebViewOpen) {
      context.pop();
      _isWebViewOpen = false;
    }
    ref.read(paymentControllerProvider.notifier).reset();

    if (!mounted) return;
    showAppSnackbar(context, text: 'Подписка активирована!', type: AppSnackbarType.success);
  }

  void _onPaymentStateChanged(PaymentState? prev, PaymentState next) {
    final ctrl = ref.read(paymentControllerProvider.notifier);
    final cfg = ref.read(appConfigProvider);

    if (!_isWebViewOpen && next is PaymentReady) {
      _isWebViewOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pushPayment(
          PaymentWebViewArgs(
            url: next.payment.confirmationUrl!,
            successPrefix: cfg.paymentSuccessPrefix,
            cancelPrefix: cfg.paymentCancelPrefix,
            onSuccess: () async {
              await ctrl.checkPaymentStatus(next.payment.id);
              _isWebViewOpen = false;
            },
            onCancel: () {
              ctrl.reset();
              if (_isWebViewOpen && mounted) context.pop();
              _isWebViewOpen = false;
            },
          ),
        );
      });
      return;
    }

    if (next is PaymentSucceeded) {
      unawaited(_onSucceededFlow());
      return;
    }

    if (next is PaymentCanceled) {
      if (_isWebViewOpen && mounted) {
        context.pop();
        _isWebViewOpen = false;
      }
      ctrl.reset();
    }
  }

  Widget _buildReadyBody(SubscriptionReady ready) {
    final t = context.tokens;
    final c = context.colors;

    final paymentState = ref.watch(paymentControllerProvider);
    final isLoadingPayment = paymentState is PaymentLoading;
    final isPolling = paymentState is PaymentPolling &&
        (paymentState.payment.status == PaymentStatus.pending ||
            paymentState.payment.status == PaymentStatus.waitingForCapture);
    final paymentError = paymentState is PaymentFailed ? paymentState.message : null;

    final desc = _describeStatus(context, ready.status);

    if (isLoadingPayment) {
      return _screen(const Center(child: CircularProgressIndicator()));
    }

    if (paymentError != null) {
      return _screen(
        Padding(
          padding: t.spacing.all(t.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatusCard(
                statusText: desc.statusText,
                periodText: desc.periodText,
                statusColor: desc.statusColor,
              ),
              SizedBox(height: t.spacing.xl),
              Text(paymentError, style: t.typography.body.copyWith(color: c.danger)),
              SizedBox(height: t.spacing.md),
              PrimaryButton(
                label: 'Попробовать снова',
                onPressed: ref.read(paymentControllerProvider.notifier).reset,
                icon: Icons.refresh_rounded,
              ),
            ],
          ),
        ),
      );
    }

    return _screen(
      Padding(
        padding: t.spacing.all(t.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatusCard(
              statusText: desc.statusText,
              periodText: desc.periodText,
              statusColor: desc.statusColor,
            ),
            const Spacer(),
            if (!ready.status.isPaid || ready.status.isTrial)
              (isPolling
                  ? const SubscriptionConfirmingBlock()
                  : PrimaryButton(
                      label: 'Оплатить',
                      icon: Icons.diamond_rounded,
                      onPressed: () => showPaymentMethodSheet(context, ref),
                    )),
            SizedBox(height: t.spacing.xs),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentControllerProvider, _onPaymentStateChanged);

    final subState = ref.watch(subscriptionControllerProvider);
    switch (subState) {
      case SubscriptionLoading():
        return _screen(const Center(child: CircularProgressIndicator()));
      case SubscriptionError(:final message):
        final t = context.tokens;
        final c = context.colors;
        return _screen(
          Padding(
            padding: t.spacing.all(t.spacing.lg),
            child: Text('Ошибка: $message', style: t.typography.body.copyWith(color: c.danger)),
          ),
        );
      case SubscriptionReady():
        return _buildReadyBody(subState);
      default:
        return _screen(const Center(child: Text('Нет данных по подписке')));
    }
  }
}
