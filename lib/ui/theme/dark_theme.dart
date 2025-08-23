// lib/ui/theme/dark_theme.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';

const _darkAppColors = AppColors(
  bgDark: Color(0xFF050301),
  bg:     Color(0xFF161208),
  bgLight:Color(0xFF201911),
  text:   Color(0xFFEBE6D7),
  textMuted: Color(0xFFAEA486),
  highlight: Color(0xFF726C5C),
  border: Color(0xFF58513D),
  borderMuted: Color(0xFF3B3321),
  primary: Color(0xFFE2C77F),
  secondary: Color(0xFFC6D6F8),
  danger: Color(0xFFB77D7A),
  warning: Color(0xFF958D74),
  success: Color(0xFF7DA189),
  info: Color(0xFF88A3C4),
);

// локальные ARGB для теней (dark)
const _kBlack20 = Color(0x33000000);
const _kBlack28 = Color(0x47000000);
const _kBlack32 = Color(0x52000000);
const _kBlack36 = Color(0x5C000000);
const _kBlack40 = Color(0x66000000);
const _kBlack44 = Color(0x70000000);

const _darkShadows = Shadows(
  z1: [BoxShadow(color: _kBlack20, blurRadius: 6,  offset: Offset(0, 2))],
  z2: [BoxShadow(color: _kBlack28, blurRadius: 10, offset: Offset(0, 4))],
  z3: [BoxShadow(color: _kBlack32, blurRadius: 14, offset: Offset(0, 6))],
  z4: [BoxShadow(color: _kBlack36, blurRadius: 20, offset: Offset(0, 8))],
  z5: [BoxShadow(color: _kBlack40, blurRadius: 28, offset: Offset(0, 12))],
  z6: [BoxShadow(color: _kBlack44, blurRadius: 36, offset: Offset(0, 16))],
);

final _darkTokens = AppTheme(
  spacing: const Spacing(),
  radii: const Radii(),
  shadows: _darkShadows,
  opacities: const Opacities(),
  typography: TypographyTokens.regular(),
  colors: _darkAppColors,
  icons: const IconSizes(),
  elevations: const Elevations(),
  durations: const DurationsTokens(),
);

final ThemeData appDarkTheme = ThemeData(
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
    headlineLarge: _darkTokens.typography.h1.copyWith(color: _darkAppColors.text),
    bodyMedium:    _darkTokens.typography.body.copyWith(color: _darkAppColors.textMuted),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: _darkTokens.elevations.none,
  ),
  extensions: <ThemeExtension<dynamic>>[
    _darkTokens,
  ],
);