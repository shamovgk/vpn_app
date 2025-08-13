// lib/ui/widgets/atoms/app_surface.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';

class AppSurface extends StatelessWidget {
  final Widget child;
  final List<BoxShadow>? shadow;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? radius;

  const AppSurface({super.key, required this.child, this.shadow, this.padding, this.radius});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.tokens;
    return Container(
      padding: padding ?? t.spacing.all(t.spacing.md),
      decoration: BoxDecoration(
        color: colors.bgLight,
        borderRadius: radius ?? t.radii.brLg,
        boxShadow: shadow ?? t.shadows.z1,
        border: Border.all(color: colors.borderMuted, width: 1),
      ),
      child: child,
    );
  }
}
