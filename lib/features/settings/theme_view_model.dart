import 'package:flutter/material.dart';

import '../../data/local/preferences_repository.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel(this.repository) : mode = repository.themeMode;
  final PreferencesRepository repository;
  ThemeMode mode;
  bool saving = false;
  String? error;

  Future<void> change(ThemeMode value) async {
    if (saving) return;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await repository.saveTheme(value);
      mode = value;
    } on Exception {
      error = 'Não foi possível salvar o tema. Tente novamente.';
    } on StateError {
      error = 'Não foi possível salvar o tema. Tente novamente.';
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
