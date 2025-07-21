import 'package:flutter/material.dart';
import 'app_colors.dart';

const _darkAppColors = AppColors(
  bgDark: Color(0xFF050301),       // hsl(38, 74%, 1%)
  bg: Color(0xFF161208),           // hsl(42, 48%, 4%)
  bgLight: Color(0xFF201911),      // hsl(44, 27%, 8%)
  text: Color(0xFFEBE6D7),         // hsl(44, 73%, 92%)
  textMuted: Color(0xFFAEA486),    // hsl(44, 17%, 67%)
  highlight: Color(0xFF726C5C),    // hsl(44, 14%, 36%)
  border: Color(0xFF58513D),       // hsl(44, 19%, 26%)
  borderMuted: Color(0xFF3B3321),  // hsl(44, 29%, 16%)
  primary: Color(0xFFE2C77F),      // hsl(44, 49%, 59%)
  secondary: Color(0xFFC6D6F8),    // hsl(225, 76%, 77%)
  danger: Color(0xFFB77D7A),       // hsl(9, 26%, 64%)
  warning: Color(0xFF958D74),      // hsl(52, 19%, 57%)
  success: Color(0xFF7DA189),      // hsl(146, 17%, 59%)
  info: Color(0xFF88A3C4),         // hsl(217, 28%, 65%)
);

final ThemeData appDarkTheme  = ThemeData(
  scaffoldBackgroundColor: _darkAppColors.bg,
  cardColor: _darkAppColors.bgLight,
  dividerColor: _darkAppColors.borderMuted,
  colorScheme: ColorScheme.dark(
    primary: _darkAppColors.primary,
    secondary: _darkAppColors.secondary,
    error: _darkAppColors.danger,
    surface: _darkAppColors.bgLight,
    onPrimary: _darkAppColors.bgLight,
    onSecondary: _darkAppColors.bgLight,
    onError: _darkAppColors.bgLight,
    onSurface: _darkAppColors.text,
  ),
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      color: _darkAppColors.text,
      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
    bodyMedium: TextStyle(
      color: _darkAppColors.textMuted,
      fontSize: 16,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: _darkAppColors.text,
    elevation: 0,
  ),
  extensions: <ThemeExtension<dynamic>>[
    _darkAppColors,
  ],
);
