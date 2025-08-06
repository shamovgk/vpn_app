import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/features/auth/providers/auth_provider.dart';
import 'package:vpn_app/features/payments/providers/payment_provider.dart';
import 'package:vpn_app/ui/widgets/app_custom_appbar.dart';
import 'package:vpn_app/ui/widgets/app_snackbar.dart';
import 'package:vpn_app/ui/widgets/themed_background.dart';
import 'package:vpn_app/ui/widgets/app_snackbar_helper.dart';
import '../widgets/status_card.dart';
import '../widgets/pay_button.dart';
import '../widgets/payment_method_sheet.dart';
import 'package:vpn_app/features/payments/screens/payment_webview_screen.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isWebViewOpen = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentProvider, (prev, next) {
      if (!_isWebViewOpen && next.paymentUrl != null) {
        _isWebViewOpen = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final notifier = ref.read(paymentProvider.notifier);
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(
              url: next.paymentUrl!,
              onSuccess: () async {
                await ref.read(authProvider.notifier).validateToken();
                notifier.reset();
                if (!mounted) return;
                showAppSnackbar(
                  context,
                  text: 'Подписка активирована!',
                  type: AppSnackbarType.success,
                );
              },
              onCancel: () {
                notifier.reset();
              },
            ),
          ));
          if (!mounted) return;
          _isWebViewOpen = false;
        });
      }
    });

    final colors = AppColors.of(context);
    final user = ref.watch(authProvider).user;
    final paymentState = ref.watch(paymentProvider);
    final notifier = ref.read(paymentProvider.notifier);

    if (user == null) {
      return ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const AppCustomAppBar(title: 'Подписка'),
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

    if (paymentState.loading) {
      return ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const AppCustomAppBar(title: 'Подписка'),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (paymentState.error != null) {
      return ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const AppCustomAppBar(title: 'Подписка'),
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

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const AppCustomAppBar(title: 'Подписка'),
        body: mainContent,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }
}
