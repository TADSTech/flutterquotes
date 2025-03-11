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
        title: Text('Settings', style: TextStyle(color: theme.colorScheme.onPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ThemeColorPicker(
            color: themeProvider.primaryColor,
            label: 'Primary Color',
            onColorChanged: themeProvider.updatePrimary,
          ),
          _ThemeColorPicker(
            color: themeProvider.secondaryColor,
            label: 'Secondary Color',
            onColorChanged: themeProvider.updateSecondary,
          ),
          SwitchListTile(
            title: Text('Dark Mode', style: TextStyle(color: theme.colorScheme.onSurface)),
            value: themeProvider.isDark,
            onChanged: themeProvider.toggleTheme,
          ),
        ],
      ),
    );
  }
}

class _ThemeColorPicker extends StatelessWidget {
  final Color color;
  final String label;
  final ValueChanged<Color> onColorChanged;

  const _ThemeColorPicker({
    required this.color,
    required this.label,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      trailing: ColorPickerButton(
        selectedColor: color,
        onColorChanged: onColorChanged,
      ),
    );
  }
}

class ColorPickerButton extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerButton({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Color>(
      itemBuilder: (context) => [
        Colors.blue,
        Colors.green,
        Colors.purple,
        Colors.orange,
        Colors.red,
        Colors.teal,
      ]
          .map((color) => PopupMenuItem(
                value: color,
                child: Container(
                  color: color,
                  width: 100,
                  height: 40,
                  alignment: Alignment.center,
                  child: selectedColor == color
                      ? Icon(Icons.check,
                          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                      : null,
                ),
              ))
          .toList(),
      onSelected: onColorChanged,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selectedColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
      ),
    );
  }
}
