// lib/ui/widgets/atoms/ghost_button.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool fullWidth;
  final double? height;

  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.fullWidth = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;
    final base = color ?? c.primary;

    final btn = TextButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: t.icons.sm, color: base) : const SizedBox.shrink(),
      label: Text(label, style: t.typography.button.copyWith(color: base)),
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: t.radii.brSm),
        padding: EdgeInsets.symmetric(
          horizontal: t.spacing.xs,
          vertical: t.spacing.xxs,
        ),
        foregroundColor: base,
      ),
    );

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: Align(alignment: Alignment.centerLeft, child: btn),
      );
    }
    return SizedBox(height: height, child: btn);
  }
}
