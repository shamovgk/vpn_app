// lib/ui/widgets/app_snackbar_helper.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/ui/widgets/app_snackbar.dart';

void showAppSnackbar(
  BuildContext context, {
  required String text,
  AppSnackbarType type = AppSnackbarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final t = context.tokens;
  final style = AppSnackbarStyle.fromType(type, context.colors);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: AppSnackbar(text: text, type: type),
      backgroundColor: style.bgColor,
      behavior: SnackBarBehavior.floating,
      elevation: 12,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: t.radii.brLg),
    ),
  );
}
