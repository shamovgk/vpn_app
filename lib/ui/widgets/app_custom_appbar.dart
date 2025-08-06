import 'package:flutter/material.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';

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
    final colors = AppColors.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          color: colors.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions,
    );
  }
}
