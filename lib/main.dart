import 'package:flutter/material.dart';
import 'package:flutterquotes/main_screen.dart';
import 'package:flutterquotes/quote_provider.dart';
import 'package:flutterquotes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final prefs = await SharedPreferences.getInstance();
    runApp(MyQuotesApp(prefs: prefs));
  } catch (e) {
    runApp(const ErrorApp());
  }
}

class MyQuotesApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyQuotesApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => QuoteProvider(prefs)),
      ],
      child: const AppContent(),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MainScreen(),
        );
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Failed to initialize app')),
      ),
    );
  }
}
