import 'package:flutter/material.dart';
import 'package:flutterquotes/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Theme Customization'),
          _ThemeColorPicker(
            currentColor: themeProvider.primaryColor,
            label: 'Primary Color',
            defaultColor: themeProvider.primaryColor,
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
            defaultColor: themeProvider.secondaryColor,
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
                themeProvider.updatePrimaryColor(themeProvider.primaryColor);
                themeProvider.updateSecondaryColor(themeProvider.secondaryColor);
              }
            },
          ),
        ],
      ),
    );
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
  final Color defaultColor;
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
                  ? Icon(Icons.check, color: isDark ? Colors.white : Colors.black)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
