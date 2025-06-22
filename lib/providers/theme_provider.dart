import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; 

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    logger.i('Theme switched to: ${_themeMode.toString()}');
    notifyListeners();
  }
}