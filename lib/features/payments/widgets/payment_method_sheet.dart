// lib/features/payments/widgets/payment_method_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/features/payments/providers/payment_providers.dart';
import 'package:vpn_app/features/payments/models/domain/payment_method.dart';

void showPaymentMethodSheet(BuildContext context, WidgetRef ref) {
  final c = context.colors;
  final t = context.tokens;
  final ctrl = ref.read(paymentControllerProvider.notifier);

  const items = [
    PaymentMethod.bankCard,
    PaymentMethod.sbp,
    PaymentMethod.sberpay,
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: c.bgLight,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(t.radii.xl)),
    ),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: t.spacing.xs),
        Container(
          width: t.spacing.xxl,
          height: t.spacing.xs * 0.6,
          margin: EdgeInsets.only(bottom: t.spacing.xs),
          decoration: BoxDecoration(
            color: c.borderMuted,
            borderRadius: BorderRadius.circular(t.radii.sm),
          ),
        ),
        for (final m in items)
          _PaymentMethodButton(
            method: m,
            onTap: () {
              Navigator.of(ctx).pop();
              ctrl.startPayment(method: m);
            },
          ),
        SizedBox(height: t.spacing.md),
      ],
    ),
  );
}

class _PaymentMethodButton extends StatelessWidget {
  final PaymentMethod method;
  final VoidCallback onTap;

  const _PaymentMethodButton({required this.method, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    IconData icon() {
      switch (method) {
        case PaymentMethod.bankCard:
          return Icons.credit_card;
        case PaymentMethod.sbp:
          return Icons.account_balance_wallet_rounded;
        case PaymentMethod.sberpay:
          return Icons.account_balance;
      }
    }

    String label() {
      switch (method) {
        case PaymentMethod.bankCard:
          return 'Картой';
        case PaymentMethod.sbp:
          return 'СБП';
        case PaymentMethod.sberpay:
          return 'СберПэй';
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.spacing.lg, vertical: t.spacing.xs),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon(), color: c.primary, size: t.icons.md),
          label: Text(label(), style: t.typography.body.copyWith(color: c.text)),
          style: ElevatedButton.styleFrom(
            backgroundColor: c.bg,
            foregroundColor: c.text,
            shape: RoundedRectangleBorder(borderRadius: t.radii.brMd),
            elevation: t.elevations.none,
            padding: EdgeInsets.symmetric(
              horizontal: t.spacing.md,
              vertical: t.spacing.sm,
            ),
          ),
        ),
      ),
    );
  }
}