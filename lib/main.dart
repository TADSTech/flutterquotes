import 'package:flutter/material.dart';
import 'package:flutterquotes/main_screen.dart';
import 'package:flutterquotes/quote_provider.dart';
import 'package:flutterquotes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => QuoteProvider(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(themeProvider, false),
          darkTheme: _buildTheme(themeProvider, true),
          themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const MainScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme(ThemeProvider provider, bool isDark) {
    return ThemeData(
      colorScheme: ColorScheme(
        primary: provider.primaryColor,
        secondary: provider.secondaryColor,
        surface: provider.surface,
        error: Colors.red,
        onPrimary: provider.onPrimary,
        onSecondary: provider.onSurface,
        onSurface: provider.onSurface,
        onError: Colors.white,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: provider.onSurface),
        bodyMedium: TextStyle(color: provider.onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: provider.primaryColor,
        foregroundColor: provider.onPrimary,
      ),
    );
  }
}
