import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/features/auth/providers/auth_provider.dart';
import 'package:vpn_app/features/payments/providers/payment_provider.dart';
import 'package:vpn_app/ui/widgets/themed_background.dart';

import '../widgets/status_card.dart';
import '../widgets/pay_button.dart';
import '../widgets/payment_method_sheet.dart';
import '../widgets/payment_webview.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final paymentState = ref.watch(paymentProvider);
    final notifier = ref.read(paymentProvider.notifier);

    if (user == null) {
      return ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const Center(child: Text('Пользователь не найден')),
        ),
      );
    }

    final now = DateTime.now();
    final trialEnd = user.trialEndDate != null ? DateTime.tryParse(user.trialEndDate!) : null;
    final paidUntil = user.paidUntil != null ? DateTime.tryParse(user.paidUntil!) : null;
    final isTrialActive = trialEnd != null && trialEnd.isAfter(now);
    final isPaid = user.isPaid;

    String statusText;
    String periodText;
    Color statusColor;
    if (isTrialActive) {
      statusText = "Пробный период";
      periodText = "Доступ до ${_formatDate(trialEnd)}";
      statusColor = colors.info;
    } else if (isPaid && paidUntil != null) {
      statusText = "Подписка активна";
      periodText = "До ${_formatDate(paidUntil)}";
      statusColor = colors.success;
    } else {
      statusText = "Подписка неактивна";
      periodText = "Нет активной подписки";
      statusColor = colors.danger;
    }

    Widget mainContent = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusCard(
            statusText: statusText,
            periodText: periodText,
            statusColor: statusColor,
          ),
          const Spacer(),
          if (!isPaid || isTrialActive)
            PayButton(
              onTap: () => showPaymentMethodSheet(context, ref),
              colors: colors,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );

    // Лоадер во время создания оплаты
    if (paymentState.loading) {
      return ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(theme, colors),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Ошибка
    if (paymentState.error != null) {
      return ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(theme, colors),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatusCard(
                  statusText: statusText,
                  periodText: periodText,
                  statusColor: statusColor,
                ),
                const SizedBox(height: 36),
                Text(paymentState.error!, style: TextStyle(color: colors.danger)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: notifier.reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.bgLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Попробовать снова'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // WebView оплаты
    if (paymentState.paymentUrl != null) {
      return ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(theme, colors, onClose: () {
            notifier.reset();
          }),
          body: PaymentWebView(
            url: paymentState.paymentUrl!,
            onPaymentSuccess: () async {
              await ref.read(authProvider.notifier).validateToken();
              notifier.reset();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Подписка активирована!'),
                    backgroundColor: AppColors.of(context).success,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ),
      );
    }

    // Основной экран
    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(theme, colors),
        body: mainContent,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, AppColors colors, {VoidCallback? onClose}) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: onClose == null,
      leading: onClose != null
          ? IconButton(
              icon: Icon(Icons.close, color: colors.textMuted),
              onPressed: onClose,
            )
          : null,
      title: Text(
        'Подписка',
        style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20, color: colors.text),
      ),
      centerTitle: true,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }
}
