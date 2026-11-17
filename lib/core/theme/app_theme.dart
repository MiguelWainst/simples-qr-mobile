import 'package:flutter/material.dart';

import '../../domain/catalog.dart';

abstract final class AppTokens {
  static const double spacing = 16;
  static const double radius = 20;
  static const double contentWidth = 840;
  static const Color seed = Color(0xFFA63D24);
}

abstract final class AppTheme {
  static Color menuSeed(String? menuAccent) {
    final hex = Rules.menuAccent(menuAccent ?? '');
    return hex == null
        ? AppTokens.seed
        : Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
  }

  static ThemeData build(Brightness brightness, {String? menuAccent}) {
    final colors = ColorScheme.fromSeed(
      seedColor: menuSeed(menuAccent),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surfaceContainerLowest,
      appBarTheme: AppBarThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        foregroundColor: colors.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
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
      chipTheme: ChipThemeData(
        side: BorderSide(color: colors.outlineVariant),
        selectedColor: colors.primaryContainer,
        shape: const StadiumBorder(),
      ),
    );
  }
}
