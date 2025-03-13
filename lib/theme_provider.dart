import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const Color _defaultPrimary = Colors.blue;
  static const Color _defaultSecondary = Colors.cyan;
  static const String _prefsKey = 'theme_settings';

  final SharedPreferences prefs;

  ThemeProvider(this.prefs) {
    _loadSavedPreferences();
  }

  static const List<Color> colorPalette = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  late ThemeMode _themeMode;
  late Color _primaryColor;
  late Color _secondaryColor;
  late bool _isDynamicColor;

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  bool get isDynamicColor => _isDynamicColor;

  void _loadSavedPreferences() {
    try {
      _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
      _primaryColor = Color(prefs.getInt('primaryColor') ?? _defaultPrimary.value);
      _secondaryColor = Color(prefs.getInt('secondaryColor') ?? _defaultSecondary.value);
      _isDynamicColor = prefs.getBool('isDynamicColor') ?? false;
    } catch (e) {
      _setDefaults();
    }
    notifyListeners();
  }

  void _setDefaults() {
    _themeMode = ThemeMode.system;
    _primaryColor = _defaultPrimary;
    _secondaryColor = _defaultSecondary;
    _isDynamicColor = false;
  }

  ColorScheme _getColorScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _secondaryColor,
      brightness: brightness,
    );
  }

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: _getColorScheme(Brightness.light),
        extensions: [_CustomColors(secondary: _secondaryColor)],
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: _getColorScheme(Brightness.dark),
        extensions: [_CustomColors(secondary: _secondaryColor)],
      );

  static _CustomColors customColors(BuildContext context) =>
      Theme.of(context).extension<_CustomColors>()!;

  Future<void> _savePreferences() async {
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setInt('primaryColor', _primaryColor.value);
    await prefs.setInt('secondaryColor', _secondaryColor.value);
    await prefs.setBool('isDynamicColor', _isDynamicColor);
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _savePreferences();
    notifyListeners();
  }

  void updatePrimaryColor(Color color) {
    _primaryColor = color;
    _savePreferences();
    notifyListeners();
  }

  void updateSecondaryColor(Color color) {
    _secondaryColor = color;
    _savePreferences();
    notifyListeners();
  }

  void toggleDynamicColor(bool value) {
    _isDynamicColor = value;
    _savePreferences();
    notifyListeners();
  }

  Color get navigationBarBackground => _colorScheme.surface;
  Color get navigationBarSelected => _colorScheme.primary;
  Color get navigationBarUnselected => _colorScheme.onSurfaceVariant;

  ColorScheme get _colorScheme =>
      _themeMode == ThemeMode.dark ? darkTheme.colorScheme : lightTheme.colorScheme;
}

class _CustomColors extends ThemeExtension<_CustomColors> {
  final Color secondary;

  const _CustomColors({required this.secondary});

  @override
  ThemeExtension<_CustomColors> copyWith({Color? secondary}) {
    return _CustomColors(secondary: secondary ?? this.secondary);
  }

  @override
  ThemeExtension<_CustomColors> lerp(ThemeExtension<_CustomColors>? other, double t) {
    if (other is! _CustomColors) return this;
    return _CustomColors(
      secondary: Color.lerp(secondary, other.secondary, t)!,
    );
  }
}
