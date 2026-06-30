import 'package:flutter/material.dart';

import '../models/repository.dart';
import '../theme/theme_controller.dart';

/// App preferences: currently just the light/dark/system appearance toggle.
class SettingsScreen extends StatefulWidget {
  final SetlistRepository repo;

  const SettingsScreen({super.key, required this.repo});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _setThemeMode(ThemeMode mode) async {
    ThemeController.mode.value = mode;
    widget.repo.themeModeName = ThemeController.nameOf(mode);
    await widget.repo.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = ThemeController.mode.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: current,
              onChanged: (mode) => _setThemeMode(mode!),
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('System default'),
                    subtitle: Text('Match this device\'s appearance setting'),
                    value: ThemeMode.system,
                  ),
                  Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    title: Text('Light'),
                    value: ThemeMode.light,
                  ),
                  Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    title: Text('Dark'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
