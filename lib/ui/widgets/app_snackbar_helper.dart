import 'package:flutter/material.dart';
import 'package:vpn_app/ui/widgets/app_snackbar.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';

void showAppSnackbar(
  BuildContext context, {
  required String text,
  AppSnackbarType type = AppSnackbarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final colors = AppColors.of(context);
  final style = AppSnackbarStyle.fromType(type, colors);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: AppSnackbar(text: text, type: type),
      backgroundColor: style.bgColor,
      behavior: SnackBarBehavior.floating,
      elevation: 12,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
