// lib/features/subscription/widgets/subscription_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/core/extensions/nav_ext.dart';
import 'package:vpn_app/ui/widgets/atoms/primary_button.dart';
import '../models/subscription_state.dart';
import 'package:vpn_app/features/subscription/providers/subscription_providers.dart';

class SubscriptionBanner extends ConsumerWidget {
  final EdgeInsets? margin;

  const SubscriptionBanner({super.key, this.margin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.tokens;

    final state = ref.watch(subscriptionControllerProvider);
    final status = state is SubscriptionReady ? state.status : null;

    if (status == null) return const SizedBox.shrink();
    if (status.isPaid || status.isTrial) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.symmetric(vertical: t.spacing.xs, horizontal: t.spacing.md),
      decoration: BoxDecoration(
        color: c.warning,
        borderRadius: t.radii.brLg,
        boxShadow: t.shadows.z2,
      ),
      padding: EdgeInsets.symmetric(horizontal: t.spacing.md, vertical: t.spacing.sm),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: c.danger, size: t.icons.lg),
          Expanded(
            child: Text(
              'Доступ ограничен — требуется оплата подписки',
              style: t.typography.body.copyWith(color: c.text, fontWeight: FontWeight.w600),
            ),
          ),
          PrimaryButton(
            label: 'Оплатить',
            onPressed: () => context.pushSubscription(),
            fullWidth: false,
            icon: Icons.diamond_rounded,
          ),
        ],
      ),
    );
  }
}


