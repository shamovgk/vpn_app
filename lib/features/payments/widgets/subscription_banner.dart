import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/features/auth/providers/auth_provider.dart';
import 'package:vpn_app/features/payments/screens/subscription_screen.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';

class SubscriptionBanner extends ConsumerWidget {
  final EdgeInsets margin;

  const SubscriptionBanner({super.key, this.margin = const EdgeInsets.symmetric(vertical: 8, horizontal: 16)});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final colors = AppColors.of(context);

    if (user == null) return const SizedBox.shrink();

    // Определяем истёк ли пробный период (или неактивна подписка)
    final now = DateTime.now();
    final trialEnd = user.trialEndDate != null ? DateTime.tryParse(user.trialEndDate!) : null;
    final isTrialActive = trialEnd != null && trialEnd.isAfter(now);
    final isPaid = user.isPaid;

    if (isPaid || isTrialActive) return const SizedBox.shrink();

    // Баннер, если не оплачено и пробный период истёк
    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: colors.warning,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.warning.withAlpha(153),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.danger, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Доступ ограничен — требуется оплата подписки',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.bgLight,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            },
            child: const Text('Оплатить'),
          )
        ],
      ),
    );
  }
}
