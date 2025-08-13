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
import 'package:vpn_app/features/subscription/providers/subscription_providers.dart';
import 'package:vpn_app/features/subscription/models/subscription_state.dart';
import 'package:vpn_app/features/subscription/widgets/subscription_confirming_block.dart';
import 'package:vpn_app/ui/widgets/app_custom_appbar.dart';
import 'package:vpn_app/ui/widgets/atoms/primary_button.dart';
import 'package:vpn_app/ui/widgets/themed_scaffold.dart';

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

  Future<void> _onSucceededFlow() async {
    await ref.read(subscriptionControllerProvider.notifier).fetch();

    if (!mounted) return;
    if (_isWebViewOpen) {
      context.pop();
      _isWebViewOpen = false;
    }

    ref.read(paymentControllerProvider.notifier).reset();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Подписка активирована!')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    // === Payment listen ===
    ref.listen<PaymentState>(paymentControllerProvider, (prev, next) async {
      if (!_isWebViewOpen && next is PaymentReady) {
        _isWebViewOpen = true;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;

          final ctrl = ref.read(paymentControllerProvider.notifier);
          final baseUrl = ref.read(httpClientProvider).options.baseUrl;
          final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

          context.pushPayment(
            PaymentWebViewArgs(
              url: next.payment.confirmationUrl!,
              successPrefix: '$base/payment-success',
              cancelPrefix: '$base/payment-cancel',
              onSuccess: () async {
                await ctrl.checkPaymentStatus(next.payment.id);
              },
              onCancel: () {
                ctrl.reset();
                if (_isWebViewOpen && mounted) context.pop();
                _isWebViewOpen = false;
              },
            ),
          );

          if (!mounted) return;
          _isWebViewOpen = false;
        });
      }

      if (next is PaymentSucceeded) {
        unawaited(_onSucceededFlow());
      }

      if (next is PaymentCanceled) {
        if (_isWebViewOpen && mounted) {
          context.pop();
          _isWebViewOpen = false;
        }
        ref.read(paymentControllerProvider.notifier).reset();
      }
    });

    // === Subscription state (sealed) ===
    final subState = ref.watch(subscriptionControllerProvider);

    if (subState is SubscriptionLoading) {
      return const ThemedScaffold(
        appBar: AppCustomAppBar(title: 'Подписка'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (subState is SubscriptionError) {
      return ThemedScaffold(
        appBar: const AppCustomAppBar(title: 'Подписка'),
        body: Center(child: Text('Ошибка: ${subState.message}')),
      );
    }

    if (subState is! SubscriptionReady) {
      return const ThemedScaffold(
        appBar: AppCustomAppBar(title: 'Подписка'),
        body: Center(child: Text('Нет данных по подписке')),
      );
    }

    final status = subState.status;

    String statusText;
    String periodText;
    Color statusColor;

    if (status.isTrial) {
      statusText = 'Пробный период';
      periodText = 'Доступ до ${status.trialEndDate.toLocalDate()}';
      statusColor = c.info;
    } else if (status.isPaid && status.paidUntil != null) {
      statusText = 'Подписка активна';
      periodText = 'До ${status.paidUntil!.toLocalDate()}';
      statusColor = c.success;
    } else {
      statusText = 'Подписка неактивна';
      periodText = 'Нет активной подписки';
      statusColor = c.danger;
    }

    // payment flags
    final paymentState = ref.watch(paymentControllerProvider);
    final bool isPaymentLoading = paymentState is PaymentLoading;
    final String? paymentError = paymentState is PaymentFailed ? paymentState.message : null;
    final bool isPolling = paymentState is PaymentPolling &&
        (paymentState.payment.status == PaymentStatus.pending || paymentState.payment.status == PaymentStatus.waitingForCapture);

    final mainContent = Padding(
      padding: t.spacing.all(t.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusCard(statusText: statusText, periodText: periodText, statusColor: statusColor),
          const Spacer(),
          if (!status.isPaid || status.isTrial)
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
    );

    if (isPaymentLoading) {
      return const ThemedScaffold(
        appBar: AppCustomAppBar(title: 'Подписка'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (paymentError != null) {
      return ThemedScaffold(
        appBar: const AppCustomAppBar(title: 'Подписка'),
        body: Padding(
          padding: t.spacing.all(t.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatusCard(statusText: statusText, periodText: periodText, statusColor: statusColor),
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

    return ThemedScaffold(
      appBar: const AppCustomAppBar(title: 'Подписка'),
      body: mainContent,
    );
  }
}