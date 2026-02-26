import 'package:flutter/material.dart';

class AppThemeColors {
  static const Color seed = Color(0xFF0F766E);
}

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppThemeColors.seed,
      brightness: Brightness.light,
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppThemeColors.seed,
      brightness: Brightness.dark,
    ),
  );

  static const ThemeMode mode = ThemeMode.system;
}