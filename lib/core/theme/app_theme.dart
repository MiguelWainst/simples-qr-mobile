import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const double spacing = 16;
  static const double radius = 20;
  static const double contentWidth = 840;
  static const Color seed = Color(0xFF126B50);
}

abstract final class AppTheme {
  static ThemeData build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: AppTokens.seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),
    );
  }
}
