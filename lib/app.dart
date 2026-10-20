import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/theme_view_model.dart';

class SimplesQrApp extends StatelessWidget {
  const SimplesQrApp({required this.theme, super.key});
  final ThemeViewModel theme;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: theme,
    builder: (_, _) => MaterialApp(
      title: 'Simples QR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: theme.mode,
      onGenerateRoute: (settings) => AppRoutes.generate(settings, theme),
    ),
  );
}
