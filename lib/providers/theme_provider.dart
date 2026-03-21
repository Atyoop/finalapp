import 'package:flutter/material.dart';
import '../main.dart'; // To access AppColors

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    AppColors.isDarkMode = isDark;
    notifyListeners();
  }
}
