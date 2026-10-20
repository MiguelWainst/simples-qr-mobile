import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/local/preferences_repository.dart';
import 'features/settings/theme_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    SimplesQrApp(theme: ThemeViewModel(PreferencesRepository(preferences))),
  );
}
