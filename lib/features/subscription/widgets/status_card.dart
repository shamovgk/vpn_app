// lib/features/subscription/widgets/status_card.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/ui/widgets/atoms/app_surface.dart';

class StatusCard extends StatelessWidget {
  final String statusText;
  final String periodText;
  final Color statusColor;

  const StatusCard({
    super.key,
    required this.statusText,
    required this.periodText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    return AppSurface(
      radius: t.radii.brLg,
      padding: t.spacing.all(t.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusText,
            style: t.typography.h2.copyWith(color: statusColor),
          ),
          SizedBox(height: t.spacing.xs),
          Text(
            periodText,
            style: t.typography.body.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}