import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkTheme = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load saved settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  // Save theme preference
  Future<void> _saveThemePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
  }

  // Save notification preference
  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Theme Toggle
          ListTile(
            title: Text('Dark Theme'),
            trailing: Switch(
              value: _isDarkTheme,
              onChanged: (value) {
                setState(() {
                  _isDarkTheme = value;
                });
                _saveThemePreference(value);
                // Apply theme change (you can use Provider or another state management solution)
                // Example: Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              },
            ),
          ),
          Divider(),

          // Notifications Toggle
          ListTile(
            title: Text('Enable Notifications'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveNotificationPreference(value);
              },
            ),
          ),
          Divider(),

          // Cloud Sync (Coming Soon)
          ListTile(
            title: Text('Cloud Sync'),
            subtitle: Text('Coming Soon'),
            trailing: Icon(Icons.cloud_upload, color: Colors.grey),
            onTap: () {
              // Show a snackbar or dialog indicating this feature is coming soon
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cloud Sync is coming soon!')),
              );
            },
          ),
          Divider(),

          // App Version
          ListTile(
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
            trailing: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}
