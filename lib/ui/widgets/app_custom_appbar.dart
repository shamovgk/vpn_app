// lib/ui/widgets/app_custom_appbar.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';

class AppCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final Widget? leading;
  final List<Widget>? actions;

  const AppCustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: t.elevations.none,
      centerTitle: centerTitle,
      leading: leading,
      title: Text(title, style: t.typography.h1.copyWith(color: c.text)),
      actions: actions,
    );
  }
}