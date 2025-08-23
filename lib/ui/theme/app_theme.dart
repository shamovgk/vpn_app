// lib/ui/theme/app_theme.dart
import 'package:flutter/material.dart';

// ===================== PALLETE =====================
class AppColors extends ThemeExtension<AppColors> {
  final Color bgDark, bg, bgLight;
  final Color text, textMuted, highlight;
  final Color border, borderMuted;
  final Color primary, secondary, danger, warning, success, info;

  const AppColors({
    required this.bgDark,
    required this.bg,
    required this.bgLight,
    required this.text,
    required this.textMuted,
    required this.highlight,
    required this.border,
    required this.borderMuted,
    required this.primary,
    required this.secondary,
    required this.danger,
    required this.warning,
    required this.success,
    required this.info,
  });

  @override
  AppColors copyWith({
    Color? bgDark, Color? bg, Color? bgLight,
    Color? text, Color? textMuted, Color? highlight,
    Color? border, Color? borderMuted,
    Color? primary, Color? secondary, Color? danger, Color? warning, Color? success, Color? info,
  }) => AppColors(
        bgDark: bgDark ?? this.bgDark,
        bg: bg ?? this.bg,
        bgLight: bgLight ?? this.bgLight,
        text: text ?? this.text,
        textMuted: textMuted ?? this.textMuted,
        highlight: highlight ?? this.highlight,
        border: border ?? this.border,
        borderMuted: borderMuted ?? this.borderMuted,
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        danger: danger ?? this.danger,
        warning: warning ?? this.warning,
        success: success ?? this.success,
        info: info ?? this.info,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgDark: Color.lerp(bgDark, other.bgDark, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      bgLight: Color.lerp(bgLight, other.bgLight, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderMuted: Color.lerp(borderMuted, other.borderMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

// ===================== TOKENS =====================
class Spacing {
  final double xxs, xs, sm, md, lg, xl, xxl, xxxl;
  const Spacing({
    this.xxs = 4,
    this.xs = 8,
    this.sm = 12,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
    this.xxxl = 64,
  });
  EdgeInsets all(double v) => EdgeInsets.all(v);
  EdgeInsets h(double v) => EdgeInsets.symmetric(horizontal: v);
  EdgeInsets v(double v) => EdgeInsets.symmetric(vertical: v);
}

class Radii {
  final double xs, sm, md, lg, xl, pill;
  const Radii({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.pill = 999, // специальный большой радиус для "pill"
  });
  BorderRadius br(double r) => BorderRadius.circular(r);
  BorderRadius get brXs => br(xs);
  BorderRadius get brSm => br(sm);
  BorderRadius get brMd => br(md);
  BorderRadius get brLg => br(lg);
  BorderRadius get brXl => br(xl);
  BorderRadius get brPill => br(pill);
}

class Shadows {
  final List<BoxShadow> z1, z2, z3, z4, z5, z6;
  const Shadows({
    required this.z1,
    required this.z2,
    required this.z3,
    required this.z4,
    required this.z5,
    required this.z6,
  });
}

class Opacities {
  final double disabled, hover, focus, pressed, scrim, overlay, divider;
  const Opacities({
    this.disabled = 0.38,
    this.hover = 0.08,
    this.focus = 0.12,
    this.pressed = 0.16,
    this.scrim = 0.50,
    this.overlay = 0.30,
    this.divider = 0.12,
  });
}

class TypographyTokens {
  final String? fontFamily;
  final TextStyle h1, h2, h3;
  final TextStyle bodyLg, body, bodySm, caption, button, mono;

  const TypographyTokens({
    required this.fontFamily,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.bodyLg,
    required this.body,
    required this.bodySm,
    required this.caption,
    required this.button,
    required this.mono,
  });

  factory TypographyTokens.regular({String? fontFamily}) {
    TextStyle s(
      double size,
      double height, {
      FontWeight w = FontWeight.w400,
      String? ff,
      double? letterSpacing,
    }) =>
        TextStyle(
          fontSize: size,
          height: height / size,
          fontWeight: w,
          fontFamily: ff,
          letterSpacing: letterSpacing,
        );
    final ff = fontFamily;
    return TypographyTokens(
      fontFamily: ff,
      h1: s(24, 32, w: FontWeight.w700, ff: ff),
      h2: s(20, 28, w: FontWeight.w600, ff: ff),
      h3: s(18, 24, w: FontWeight.w600, ff: ff),
      bodyLg: s(18, 26, ff: ff),
      body: s(16, 24, ff: ff),
      bodySm: s(14, 20, ff: ff),
      caption: s(12, 16, ff: ff),
      button: s(16, 20, w: FontWeight.w600, ff: ff),
      mono: const TextStyle(fontSize: 13, height: 18 / 13, fontFamily: 'monospace'),
    );
  }
}

// Новые токены: размеры иконок, уровни elevation, длительности анимаций/таймингов
class IconSizes {
  final double xs, sm, md, lg, xl;
  const IconSizes({
    this.xs = 16,
    this.sm = 20,
    this.md = 24,
    this.lg = 28, // часто используемый размер (например, в Snackbar)
    this.xl = 32,
  });
}

class Elevations {
  final double none, xs, sm, md, lg, xl, xxl;
  const Elevations({
    this.none = 0,
    this.xs = 1,
    this.sm = 2,
    this.md = 4,
    this.lg = 8,
    this.xl = 12, // соответствует частому кейсу (SnackBar/картам)
    this.xxl = 24,
  });
}

class DurationsTokens {
  final Duration fast, normal, slow, snackbar;
  const DurationsTokens({
    this.fast = const Duration(milliseconds: 150),
    this.normal = const Duration(milliseconds: 250),
    this.slow = const Duration(milliseconds: 400),
    this.snackbar = const Duration(seconds: 3), // дефолт для Snackbar
  });
}

// ===================== THEME EXTENSION =====================
class AppTheme extends ThemeExtension<AppTheme> {
  final Spacing spacing;
  final Radii radii;
  final Shadows shadows;
  final Opacities opacities;
  final TypographyTokens typography;
  final AppColors colors;

  // Новые токены:
  final IconSizes icons;
  final Elevations elevations;
  final DurationsTokens durations;

  const AppTheme({
    required this.spacing,
    required this.radii,
    required this.shadows,
    required this.opacities,
    required this.typography,
    required this.colors,
    this.icons = const IconSizes(),
    this.elevations = const Elevations(),
    this.durations = const DurationsTokens(),
  });

  @override
  AppTheme copyWith({
    Spacing? spacing,
    Radii? radii,
    Shadows? shadows,
    Opacities? opacities,
    TypographyTokens? typography,
    AppColors? colors,
    IconSizes? icons,
    Elevations? elevations,
    DurationsTokens? durations,
  }) {
    return AppTheme(
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      shadows: shadows ?? this.shadows,
      opacities: opacities ?? this.opacities,
      typography: typography ?? this.typography,
      colors: colors ?? this.colors,
      icons: icons ?? this.icons,
      elevations: elevations ?? this.elevations,
      durations: durations ?? this.durations,
    );
  }

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) return this;
    return AppTheme(
      spacing: t < .5 ? spacing : other.spacing,
      radii: t < .5 ? radii : other.radii,
      shadows: t < .5 ? shadows : other.shadows,
      opacities: t < .5 ? opacities : other.opacities,
      typography: t < .5 ? typography : other.typography,
      colors: colors.lerp(other.colors, t),
      icons: t < .5 ? icons : other.icons,
      elevations: t < .5 ? elevations : other.elevations,
      durations: t < .5 ? durations : other.durations,
    );
  }
}
