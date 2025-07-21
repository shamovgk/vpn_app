import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color bgDark;
  final Color bg;
  final Color bgLight;
  final Color text;
  final Color textMuted;
  final Color highlight;
  final Color border;
  final Color borderMuted;
  final Color primary;
  final Color secondary;
  final Color danger;
  final Color warning;
  final Color success;
  final Color info;

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
    Color? bgDark,
    Color? bg,
    Color? bgLight,
    Color? text,
    Color? textMuted,
    Color? highlight,
    Color? border,
    Color? borderMuted,
    Color? primary,
    Color? secondary,
    Color? danger,
    Color? warning,
    Color? success,
    Color? info,
  }) {
    return AppColors(
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
  }

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

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;
}
