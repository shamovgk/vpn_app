// lib/ui/widgets/app_snackbar.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/ui/theme/app_theme.dart';

enum AppSnackbarType { success, error, info, warning }

class AppSnackbar extends StatelessWidget {
  final String text;
  final AppSnackbarType type;

  const AppSnackbar({
    super.key,
    required this.text,
    this.type = AppSnackbarType.info,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;
    final style = AppSnackbarStyle.fromType(type, c);

    return Row(
      children: [
        Icon(style.icon, color: style.iconColor, size: 28),
        SizedBox(width: t.spacing.sm),
        Expanded(
          child: Text(
            text,
            style: t.typography.body.copyWith(
              color: style.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class AppSnackbarStyle {
  final Color bgColor;
  final Color textColor;
  final Color iconColor;
  final IconData icon;

  AppSnackbarStyle({
    required this.bgColor,
    required this.textColor,
    required this.iconColor,
    required this.icon,
  });

  static AppSnackbarStyle fromType(AppSnackbarType type, AppColors colors) {
    switch (type) {
      case AppSnackbarType.success:
        return AppSnackbarStyle(
          bgColor: colors.success,
          textColor: colors.bgLight,
          iconColor: colors.bgLight,
          icon: Icons.check_circle_rounded,
        );
      case AppSnackbarType.error:
        return AppSnackbarStyle(
          bgColor: colors.danger,
          textColor: colors.bgLight,
          iconColor: colors.bgLight,
          icon: Icons.error_rounded,
        );
      case AppSnackbarType.warning:
        return AppSnackbarStyle(
          bgColor: colors.warning,
          textColor: colors.text,
          iconColor: colors.danger,
          icon: Icons.warning_amber_rounded,
        );
      case AppSnackbarType.info:
        return AppSnackbarStyle(
          bgColor: colors.info,
          textColor: colors.bgLight,
          iconColor: colors.bgLight,
          icon: Icons.info_rounded,
        );
    }
  }
}
