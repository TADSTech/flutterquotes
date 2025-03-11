import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  Color _primaryColor = Colors.blue;
  Color _secondaryColor = Colors.green;

  bool get isDark => _isDark;
  Color get primaryColor => _isDark ? Colors.blueGrey : _primaryColor;
  Color get secondaryColor => _isDark ? Colors.lightGreen : _secondaryColor;

  Color get background => _isDark ? Colors.grey[900]! : Colors.white;
  Color get surface => _isDark ? Colors.grey[800]! : Colors.white;
  Color get navigationBarBackground => _isDark ? Colors.grey[850]! : Colors.grey[50]!;
  Color get onPrimary => _isDark ? Colors.white : Colors.black;
  Color get onSurface => _isDark ? Colors.white70 : Colors.black87;
  Color get navigationBarSelected => primaryColor;
  Color get navigationBarUnselected => _isDark ? Colors.grey[500]! : Colors.grey[600]!;

  void toggleTheme(bool value) {
    _isDark = value;
    notifyListeners();
  }

  void updatePrimary(Color color) {
    _primaryColor = color;
    notifyListeners();
  }

  void updateSecondary(Color color) {
    _secondaryColor = color;
    notifyListeners();
  }
}
