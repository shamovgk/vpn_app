import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/features/payments/providers/payment_provider.dart';

void showPaymentMethodSheet(BuildContext context, WidgetRef ref) {
  final colors = AppColors.of(context);
  final notifier = ref.read(paymentProvider.notifier);

  showModalBottomSheet(
    context: context,
    backgroundColor: colors.bgLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 48,
          height: 5,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: colors.borderMuted,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        _PaymentMethodButton(
          icon: Icons.credit_card,
          label: 'Картой',
          onTap: () {
            Navigator.of(ctx).pop();
            notifier.fetchPaymentUrl('bank_card');
          },
        ),
        _PaymentMethodButton(
          icon: Icons.account_balance_wallet_rounded,
          label: 'СБП',
          onTap: () {
            Navigator.of(ctx).pop();
            notifier.fetchPaymentUrl('sbp');
          },
        ),
        _PaymentMethodButton(
          icon: Icons.account_balance,
          label: 'СберПей',
          onTap: () {
            Navigator.of(ctx).pop();
            notifier.fetchPaymentUrl('sberbank');
          },
        ),
        const SizedBox(height: 18),
      ],
    ),
  );
}

class _PaymentMethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PaymentMethodButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: colors.primary, size: 26),
          label: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 17, color: colors.text)),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.bg,
            foregroundColor: colors.text,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
