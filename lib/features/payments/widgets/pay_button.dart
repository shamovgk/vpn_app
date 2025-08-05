import 'package:flutter/material.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';

class PayButton extends StatelessWidget {
  final VoidCallback onTap;
  final AppColors colors;

  const PayButton({super.key, required this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.bgLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 2,
          textStyle: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 18, fontWeight: FontWeight.w600, color: colors.bgLight,
          ),
        ),
        icon: const Icon(Icons.diamond_rounded, size: 24),
        label: const Text('Оплатить'),
      ),
    );
  }
}
