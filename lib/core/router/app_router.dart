import 'package:flutter/material.dart';

import '../../features/home/home_view.dart';
import '../../features/settings/settings_view.dart';
import '../../features/settings/theme_view_model.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const settings = '/settings';

  static Route<void> generate(RouteSettings settings, ThemeViewModel theme) =>
      MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => switch (settings.name) {
          AppRoutes.settings => SettingsView(viewModel: theme),
          _ => HomeView(
            onSettings: () =>
                Navigator.of(context).pushNamed<void>(AppRoutes.settings),
          ),
        },
      );
}
