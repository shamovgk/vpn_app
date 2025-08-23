// lib/ui/widgets/atoms/primary_button.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double? height;
  final Color? color;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.height,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    final btn = ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: t.icons.md) : const SizedBox.shrink(),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? c.primary,
        foregroundColor: textColor ?? c.bgLight,
        textStyle: t.typography.button,
        shape: RoundedRectangleBorder(borderRadius: t.radii.brMd),
        elevation: t.elevations.sm,
        padding: EdgeInsets.symmetric(
          horizontal: t.spacing.md,
          vertical: t.spacing.xs,
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, height: height, child: btn);
    }
    return SizedBox(height: height, child: btn);
  }
}