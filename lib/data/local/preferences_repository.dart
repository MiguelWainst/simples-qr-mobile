import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesRepository {
  PreferencesRepository(this.preferences);
  final SharedPreferences preferences;

  ThemeMode get themeMode => switch (preferences.getString('theme')) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> saveTheme(ThemeMode mode) async {
    final saved = await preferences.setString('theme', mode.name);
    if (!saved) throw StateError('Preference was not saved');
  }
}
