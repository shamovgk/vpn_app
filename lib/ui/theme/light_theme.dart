// lib/ui/theme/light_theme.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';

const _lightAppColors = AppColors(
  bgDark: Color(0xFFEAE7DA),
  bg:     Color(0xFFF7F5ED),
  bgLight:Color(0xFFFFFEFB),
  text:   Color(0xFF241F12),
  textMuted: Color(0xFF58513D),
  highlight: Color(0xFFFCFAF5),
  border: Color(0xFF9A9277),
  borderMuted: Color(0xFFBBB49A),
  primary: Color(0xFF6C5609),
  secondary: Color(0xFF373F62),
  danger: Color(0xFF593A36),
  warning: Color(0xFF6D6645),
  success: Color(0xFF375140),
  info: Color(0xFF3D475B),
);

// локальные ARGB для теней (light)
const _kBlack12 = Color(0x1F000000);
const _kBlack16 = Color(0x29000000);
const _kBlack20 = Color(0x33000000);
const _kBlack24 = Color(0x3D000000);
const _kBlack28 = Color(0x47000000);
const _kBlack32 = Color(0x52000000);

const _lightShadows = Shadows(
  z1: [BoxShadow(color: _kBlack12, blurRadius: 6,  offset: Offset(0, 2))],
  z2: [BoxShadow(color: _kBlack16, blurRadius: 10, offset: Offset(0, 4))],
  z3: [BoxShadow(color: _kBlack20, blurRadius: 14, offset: Offset(0, 6))],
  z4: [BoxShadow(color: _kBlack24, blurRadius: 20, offset: Offset(0, 8))],
  z5: [BoxShadow(color: _kBlack28, blurRadius: 28, offset: Offset(0, 12))],
  z6: [BoxShadow(color: _kBlack32, blurRadius: 36, offset: Offset(0, 16))],
);

final _lightTokens = AppTheme(
  spacing: const Spacing(),
  radii: const Radii(),
  shadows: _lightShadows,
  opacities: const Opacities(),
  typography: TypographyTokens.regular(),
  colors: _lightAppColors,
  icons: const IconSizes(),
  elevations: const Elevations(),
  durations: const DurationsTokens(),
);

final ThemeData appLightTheme = ThemeData(
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
    headlineLarge: _lightTokens.typography.h1.copyWith(color: _lightAppColors.text),
    bodyMedium:    _lightTokens.typography.body.copyWith(color: _lightAppColors.textMuted),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: _lightTokens.elevations.none,
  ),
  extensions: <ThemeExtension<dynamic>>[
    _lightTokens,
  ],
);