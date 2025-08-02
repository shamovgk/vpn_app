import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/ui/widgets/themed_background.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payments/screens/payment_screen.dart';

class SubscriptionStatusScreen extends ConsumerWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final user = ref.watch(authProvider).user;
    final theme = Theme.of(context);

    if (user == null) {
      return ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Статус подписки')),
          body: const Center(child: Text("Пользователь не найден")),
        ),
      );
    }

    final now = DateTime.now();
    final trialEnd = user.trialEndDate != null ? DateTime.tryParse(user.trialEndDate!) : null;
    final paidUntil = user.paidUntil != null ? DateTime.tryParse(user.paidUntil!) : null;
    final isTrialActive = trialEnd != null && trialEnd.isAfter(now);
    final isPaid = user.isPaid;
    final hasActiveSub = isPaid || isTrialActive;

    String statusText;
    String periodText;
    if (isTrialActive) {
      statusText = "Пробный период";
      periodText = "Доступ до ${_formatDate(trialEnd)}";
    } else if (isPaid && paidUntil != null) {
      statusText = "Подписка активна";
      periodText = "До ${_formatDate(paidUntil)}";
    } else {
      statusText = "Подписка неактивна";
      periodText = "Нет активной подписки";
    }

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text("Статус подписки", style: theme.textTheme.headlineSmall?.copyWith(color: colors.text)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: colors.bgLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(statusText, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.text)),
                      const SizedBox(height: 10),
                      Text(periodText, style: TextStyle(fontSize: 16, color: colors.textMuted)),
                      const SizedBox(height: 18),
                      Text(
                        "Тариф: ${user.subscriptionLevel == 1 ? 'Plus (до 6 устройств)' : 'Basic (до 3 устройств)'}",
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (!hasActiveSub)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.bgLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
                  child: const Text("Оплатить подписку"),
                ),
              if (isTrialActive || isPaid)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.bgLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
                  child: Text(isTrialActive ? "Оплатить после триала" : "Продлить подписку"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }
}
