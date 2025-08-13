// lib/ui/widgets/atoms/secondary_button.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double? height;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    final btn = OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 20, color: c.primary) : const SizedBox.shrink(),
      label: Text(label, style: t.typography.button.copyWith(color: c.primary)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: c.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: t.radii.brMd),
        padding: EdgeInsets.symmetric(
          horizontal: t.spacing.md,
          vertical: t.spacing.xs,
        ),
        foregroundColor: c.primary,
        backgroundColor: c.bg,
      ),
    );

    final h = height ?? 48.0;
    return fullWidth ? SizedBox(width: double.infinity, height: h, child: btn) : SizedBox(height: h, child: btn);
  }
}
