import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterquotes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences _prefs;
  bool _isLoading = true;
  String _selectedFont = 'Default';
  bool _developerMode = false;

  static const List<String> _availableFonts = [
    'Default',
    'Serif',
    'Sans-serif',
    'Monospace',
    'Handwriting'
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedFont = _prefs.getString('quote_font') ?? 'Default';
      _developerMode = _prefs.getBool('developer_mode') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveFontPreference(String font) async {
    await _prefs.setString('quote_font', font);
    setState(() => _selectedFont = font);
  }

  Future<void> _toggleDeveloperMode(bool value) async {
    await _prefs.setBool('developer_mode', value);
    setState(() => _developerMode = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        centerTitle: true,
        actions: [
          if (_developerMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _showDeveloperOptions,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Theme Customization'),
          _ThemeColorPicker(
            currentColor: themeProvider.primaryColor,
            label: 'Primary Color',
            defaultColor: ThemeProvider.defaultPrimary, // Corrected
            onColorChanged: (color) {
              themeProvider.updatePrimaryColor(color);
              if (themeProvider.isDynamicColor) {
                themeProvider.toggleDynamicColor(false);
              }
            },
          ),
          _ThemeColorPicker(
            currentColor: themeProvider.secondaryColor,
            label: 'Secondary Color',
            defaultColor: ThemeProvider.defaultSecondary, // Corrected
            onColorChanged: (color) {
              themeProvider.updateSecondaryColor(color);
              if (themeProvider.isDynamicColor) {
                themeProvider.toggleDynamicColor(false);
              }
            },
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Display Settings'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<ThemeMode>(
              value: themeProvider.themeMode,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System Default'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light Theme'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark Theme'),
                ),
              ],
              onChanged: (mode) => themeProvider.setThemeMode(mode!),
              decoration: const InputDecoration(
                labelText: 'Theme Mode',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Dynamic Colors'),
            subtitle: const Text('Use system color scheme'),
            value: themeProvider.isDynamicColor,
            onChanged: (value) {
              themeProvider.toggleDynamicColor(value);
              if (value) {
                themeProvider.updatePrimaryColor(ThemeProvider.defaultPrimary);
                themeProvider
                    .updateSecondaryColor(ThemeProvider.defaultSecondary);
              }
            },
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Quote Customization'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: _selectedFont,
              items: _availableFonts.map((font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(font),
                );
              }).toList(),
              onChanged: (font) => _saveFontPreference(font!),
              decoration: const InputDecoration(
                labelText: 'Quote Font Style',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            onTap: _showAboutDialog,
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Licenses'),
            onTap: _showLicensePage,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () => _launchUrl(
                'https://docs.google.com/document/d/1X55M2PjAOn6GXKpOv7iMqljbIT__VnZ9YGaUZHCbfng/edit?usp=sharing'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Terms of Service'),
            onTap: () => _launchUrl(
                'https://docs.google.com/document/d/15cnD1fOSfhMiTlJ1qz-GP4HHLmLTNuDVV0DxzYHf5hw/edit?usp=sharing'),
          ),
          if (_developerMode) ...[
            const SizedBox(height: 16),
            _SectionHeader(title: 'Developer Options'),
            SwitchListTile(
              title: const Text('Developer Mode'),
              value: _developerMode,
              onChanged: _toggleDeveloperMode,
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Debug Information'),
              onTap: _showDebugInfo,
            ),
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: const Text('Reset All Settings'),
              onTap: _resetSettings,
            ),
          ],
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'FlutterQuotes',
      applicationVersion: '1.4.0',
      applicationLegalese: '© 2024 T.A.D.S',
      children: [
        const SizedBox(height: 16),
        const Text('An inspirational quotes app built with Flutter'),
      ],
    );
  }

  void _showLicensePage() {
    showLicensePage(
      context: context,
      applicationName: 'FlutterQuotes',
      applicationVersion: '1.4.0',
      applicationLegalese: '© 2024 T.A.D.S',
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (!await launchUrl(Uri.parse(url))) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open: $e')),
      );
    }
  }

  void _showDeveloperOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Advanced settings for development and testing'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDebugInfo();
              },
              child: const Text('View Debug Info'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDebugInfo() {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Theme Mode: ${themeProvider.themeMode.toString().split('.').last}'),
              Text('Primary Color: ${themeProvider.primaryColor}'),
              Text('Secondary Color: ${themeProvider.secondaryColor}'),
              Text('Dynamic Color: ${themeProvider.isDynamicColor}'),
              Text('Quote Font: $_selectedFont'),
              const SizedBox(height: 16),
              Text(
                  'Brightness: ${theme.brightness.toString().split('.').last}'),
              Text(
                  'Platform: ${Theme.of(context).platform.toString().split('.').last}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Construct the debug info string
              final String debugInfo = '''
Theme Mode: ${themeProvider.themeMode.toString().split('.').last}
Primary Color: ${themeProvider.primaryColor}
Secondary Color: ${themeProvider.secondaryColor}
Dynamic Color: ${themeProvider.isDynamicColor}
Quote Font: $_selectedFont

Brightness: ${theme.brightness.toString().split('.').last}
Platform: ${Theme.of(context).platform.toString().split('.').last}
              ''';
              Clipboard.setData(ClipboardData(text: debugInfo));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debug info copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text(
            'This will restore all settings to their default values.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _prefs.clear();
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.setThemeMode(ThemeMode.system);
      themeProvider
          .updatePrimaryColor(ThemeProvider.defaultPrimary); // Corrected
      themeProvider
          .updateSecondaryColor(ThemeProvider.defaultSecondary); // Corrected
      themeProvider.toggleDynamicColor(false);

      setState(() {
        _selectedFont = 'Default';
        _developerMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings reset to defaults')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ThemeColorPicker extends StatelessWidget {
  final Color currentColor;
  final String label;
  final Color defaultColor; // This now correctly represents the fixed default
  final ValueChanged<Color> onColorChanged;

  const _ThemeColorPicker({
    required this.currentColor,
    required this.label,
    required this.defaultColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorPickerButton(
            selectedColor: currentColor,
            onColorChanged: onColorChanged,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset to default',
            onPressed: () => onColorChanged(defaultColor),
          ),
        ],
      ),
    );
  }
}

class ColorPickerButton extends StatelessWidget {
  static const List<Color> colorPalette = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
    Colors.deepOrange,
  ];

  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerButton({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: 'Select color',
      child: PopupMenuButton<Color>(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: selectedColor,
            enabled: false,
            child: _ColorSwatchGrid(
              selectedColor: selectedColor,
              onColorSelected: onColorChanged,
              isDark: isDark,
            ),
          ),
        ],
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selectedColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchGrid extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final bool isDark;

  const _ColorSwatchGrid({
    required this.selectedColor,
    required this.onColorSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: ColorPickerButton.colorPalette.map((color) {
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color == selectedColor
                      ? (isDark ? Colors.white : Colors.black)
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: color == selectedColor
                  ? Icon(Icons.check,
                      color: isDark ? Colors.white : Colors.black)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
