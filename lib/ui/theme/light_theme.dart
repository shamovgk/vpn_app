import 'package:flutter/material.dart';
import 'app_colors.dart';

const _lightAppColors = AppColors(
  bgDark: Color(0xFFEAE7DA),       // hsl(44, 24%, 88%)
  bg: Color(0xFFF7F5ED),           // hsl(44, 44%, 93%)
  bgLight: Color(0xFFFFFEFB),      // hsl(44, 100%, 99%)
  text: Color(0xFF241F12),         // hsl(39, 98%, 3%)
  textMuted: Color(0xFF58513D),    // hsl(44, 19%, 26%)
  highlight: Color(0xFFFCFAF5),    // hsl(44, 100%, 97%)
  border: Color(0xFF9A9277),       // hsl(44, 11%, 48%)
  borderMuted: Color(0xFFBBB49A),  // hsl(44, 13%, 59%)
  primary: Color(0xFF6C5609),      // hsl(47, 100%, 13%)
  secondary: Color(0xFF373F62),    // hsl(227, 42%, 35%)
  danger: Color(0xFF593A36),       // hsl(9, 21%, 41%)
  warning: Color(0xFF6D6645),      // hsl(52, 23%, 34%)
  success: Color(0xFF375140),      // hsl(147, 19%, 36%)
  info: Color(0xFF3D475B),         // hsl(217, 22%, 41%)
);

final ThemeData appLightTheme  = ThemeData(
  scaffoldBackgroundColor: _lightAppColors.bg,
  cardColor: _lightAppColors.bgLight,
  dividerColor: _lightAppColors.borderMuted,
  colorScheme: ColorScheme.light(
    primary: _lightAppColors.primary,
    secondary: _lightAppColors.secondary,
    error: _lightAppColors.danger,
    surface: _lightAppColors.bgLight,
    onPrimary: _lightAppColors.bgLight,
    onSecondary: _lightAppColors.bgLight,
    onError: _lightAppColors.bgLight,
    onSurface: _lightAppColors.text,
  ),
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      color: _lightAppColors.text,
      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
    bodyMedium: TextStyle(
      color: _lightAppColors.textMuted,
      fontSize: 16,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: _lightAppColors.text,
    elevation: 0,
  ),
  extensions: <ThemeExtension<dynamic>>[
    _lightAppColors,
  ],
);
