import 'package:flutter/material.dart';

// Определение кастомного расширения темы
class CustomColors extends ThemeExtension<CustomColors> {
  final Color warning;
  final Color success;
  final Color info;

  CustomColors({required this.warning, required this.success, required this.info});

  @override
  CustomColors copyWith({Color? warning, Color? success, Color? info}) {
    return CustomColors(
      warning: warning ?? this.warning,
      success: success ?? this.success,
      info: info ?? this.info,
    );
  }

  @override
  CustomColors lerp(CustomColors? other, double t) {
    if (other == null) return this;
    return CustomColors(
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // Определение тем
  ThemeData get darkTheme {
    return ThemeData(
      primaryColor: HSLColor.fromAHSL(1.0, 42, 0.51, 0.60).toColor(), // --primary: hsl(42 51% 60%)
      scaffoldBackgroundColor: HSLColor.fromAHSL(1.0, 40, 0.48, 0.04).toColor(), // --bg: hsl(40 48% 4%)
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: HSLColor.fromAHSL(1.0, 42, 0.77, 0.92).toColor(), // --text: hsl(42 77% 92%)
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(
          color: HSLColor.fromAHSL(1.0, 42, 0.17, 0.67).toColor(), // --text-muted: hsl(42 17% 67%)
          fontSize: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HSLColor.fromAHSL(1.0, 42, 0.51, 0.60).toColor(), // --primary
          foregroundColor: HSLColor.fromAHSL(1.0, 42, 0.77, 0.92).toColor(), // --text
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: HSLColor.fromAHSL(1.0, 42, 0.51, 0.60).toColor(),
        secondary: HSLColor.fromAHSL(1.0, 223, 0.77, 0.76).toColor(), // --secondary
        error: HSLColor.fromAHSL(1.0, 9, 0.26, 0.64).toColor(), // --danger
      ),
      extensions: <ThemeExtension<dynamic>>[
        CustomColors(
          warning: HSLColor.fromAHSL(1.0, 52, 0.19, 0.57).toColor(), // --warning
          success: HSLColor.fromAHSL(1.0, 146, 0.17, 0.59).toColor(), // --success
          info: HSLColor.fromAHSL(1.0, 217, 0.28, 0.65).toColor(), // --info
        ),
      ],
    );
  }

  ThemeData get lightTheme {
    return ThemeData(
      primaryColor: HSLColor.fromAHSL(1.0, 46, 1.0, 0.14).toColor(), // --primary: hsl(46 100% 14%)
      scaffoldBackgroundColor: HSLColor.fromAHSL(1.0, 42, 0.46, 0.93).toColor(), // --bg: hsl(42 46% 93%)
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: HSLColor.fromAHSL(1.0, 36, 0.98, 0.03).toColor(), // --text: hsl(36 98% 3%)
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(
          color: HSLColor.fromAHSL(1.0, 42, 0.19, 0.26).toColor(), // --text-muted: hsl(42 19% 26%)
          fontSize: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HSLColor.fromAHSL(1.0, 46, 1.0, 0.14).toColor(), // --primary
          foregroundColor: HSLColor.fromAHSL(1.0, 36, 0.98, 0.03).toColor(), // --text
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: HSLColor.fromAHSL(1.0, 46, 1.0, 0.14).toColor(),
        secondary: HSLColor.fromAHSL(1.0, 224, 0.45, 0.34).toColor(), // --secondary
        error: HSLColor.fromAHSL(1.0, 9, 0.21, 0.41).toColor(), // --danger
      ),
      extensions: <ThemeExtension<dynamic>>[
        CustomColors(
          warning: HSLColor.fromAHSL(1.0, 52, 0.23, 0.34).toColor(), // --warning
          success: HSLColor.fromAHSL(1.0, 147, 0.19, 0.36).toColor(), // --success
          info: HSLColor.fromAHSL(1.0, 217, 0.22, 0.41).toColor(), // --info
        ),
      ],
    );
  }

  ThemeData get currentTheme => _themeMode == ThemeMode.dark ? darkTheme : lightTheme;
}