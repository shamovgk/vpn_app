import 'package:flutter/material.dart';
import 'package:vpn_app/ui/theme/app_theme.dart';

extension BuildContextThemeX on BuildContext {
  AppTheme get tokens => Theme.of(this).extension<AppTheme>()!;
  AppColors get colors => tokens.colors;
}
