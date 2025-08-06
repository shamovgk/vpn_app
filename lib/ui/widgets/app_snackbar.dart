import 'package:flutter/material.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';

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
    final colors = AppColors.of(context);
    final style = AppSnackbarStyle.fromType(type, colors);

    return Row(
      children: [
        Icon(style.icon, color: style.iconColor, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
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
