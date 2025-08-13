// lib/ui/widgets/atoms/primary_button.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double? height;          // по умолчанию 56
  final Color? color;            // кастомный фон при необходимости
  final Color? textColor;        // кастомный цвет текста/иконки

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
      icon: icon != null ? Icon(icon, size: 22) : const SizedBox.shrink(),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? c.primary,
        foregroundColor: textColor ?? c.bgLight,
        textStyle: t.typography.button,
        shape: RoundedRectangleBorder(borderRadius: t.radii.brMd),
        elevation: 2,
        padding: EdgeInsets.symmetric(
          horizontal: t.spacing.md,
          vertical: t.spacing.xs,
        ),
      ),
    );

    final h = height ?? 56.0;
    return fullWidth ? SizedBox(width: double.infinity, height: h, child: btn) : SizedBox(height: h, child: btn);
  }
}

