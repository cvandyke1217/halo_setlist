import 'package:flutter/material.dart';

/// App-wide [ThemeMode] selection, shared between [MaterialApp] and the
/// settings screen via a [ValueNotifier].
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static const _names = {
    ThemeMode.system: 'system',
    ThemeMode.light: 'light',
    ThemeMode.dark: 'dark',
  };

  static String nameOf(ThemeMode mode) => _names[mode]!;

  static ThemeMode fromName(String? name) =>
      _names.entries.firstWhere((e) => e.value == name, orElse: () => _names.entries.first).key;
}
