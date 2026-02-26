import 'package:flutter/material.dart';

class AppThemeConfig {
  const AppThemeConfig({
    required this.seedColor,
    this.themeMode = ThemeMode.system,
    this.contrastLevel = 0.0,
    this.dynamicSchemeVariant = DynamicSchemeVariant.expressive,
    this.usePlatformDynamicColors = false,
  });

  static const AppThemeConfig fallback = AppThemeConfig(
    seedColor: Color.fromARGB(255, 97, 0, 242),
  );

  final Color seedColor;
  final ThemeMode themeMode;
  final double contrastLevel;
  final DynamicSchemeVariant dynamicSchemeVariant;
  final bool usePlatformDynamicColors;

  AppThemeConfig copyWith({
    Color? seedColor,
    ThemeMode? themeMode,
    double? contrastLevel,
    DynamicSchemeVariant? dynamicSchemeVariant,
    bool? usePlatformDynamicColors,
  }) {
    return AppThemeConfig(
      seedColor: seedColor ?? this.seedColor,
      themeMode: themeMode ?? this.themeMode,
      contrastLevel: contrastLevel ?? this.contrastLevel,
      dynamicSchemeVariant: dynamicSchemeVariant ?? this.dynamicSchemeVariant,
      usePlatformDynamicColors:
          usePlatformDynamicColors ?? this.usePlatformDynamicColors,
    );
  }

  factory AppThemeConfig.fromBackend(Map<String, dynamic> payload) {
    return AppThemeConfig(
      seedColor: parseSeedColor(payload['seedColor']?.toString()),
      themeMode: _parseThemeMode(payload['themeMode']?.toString()),
      contrastLevel: _parseContrastLevel(payload['contrastLevel']),
      dynamicSchemeVariant:
          _parseDynamicSchemeVariant(payload['schemeVariant']?.toString()),
      usePlatformDynamicColors:
          payload['usePlatformDynamicColors'] as bool? ?? false,
    );
  }

  static ThemeMode _parseThemeMode(String? value) {
    switch (value?.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static DynamicSchemeVariant _parseDynamicSchemeVariant(String? value) {
    switch (value?.toLowerCase()) {
      case 'fidelity':
        return DynamicSchemeVariant.fidelity;
      case 'vibrant':
        return DynamicSchemeVariant.vibrant;
      case 'expressive':
        return DynamicSchemeVariant.expressive;
      case 'content':
        return DynamicSchemeVariant.content;
      case 'monochrome':
        return DynamicSchemeVariant.monochrome;
      case 'neutral':
        return DynamicSchemeVariant.neutral;
      case 'rainbow':
        return DynamicSchemeVariant.rainbow;
      case 'fruitsalad':
        return DynamicSchemeVariant.fruitSalad;
      default:
        return DynamicSchemeVariant.expressive;
    }
  }

  static double _parseContrastLevel(dynamic value) {
    final parsed = switch (value) {
      final num numberValue => numberValue.toDouble(),
      final String stringValue => double.tryParse(stringValue),
      _ => null,
    };

    if (parsed == null) {
      return 0.0;
    }

    return parsed.clamp(-1.0, 1.0);
  }

  static Color parseSeedColor(String? value, {Color? fallback}) {
    final fallbackColor = fallback ?? AppThemeConfig.fallback.seedColor;
    if (value == null || value.trim().isEmpty) {
      return fallbackColor;
    }

    final normalized = value.trim().replaceFirst('#', '');
    final hex = switch (normalized.length) {
      6 => 'FF$normalized',
      8 => normalized,
      _ => '',
    };

    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) {
      return fallbackColor;
    }

    return Color(parsed);
  }
}

class AppTheme {
  static ThemeData light({
    required AppThemeConfig config,
    ColorScheme? platformDynamicScheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _resolveColorScheme(
        brightness: Brightness.light,
        config: config,
        platformDynamicScheme: platformDynamicScheme,
      ),
    );
  }

  static ThemeData dark({
    required AppThemeConfig config,
    ColorScheme? platformDynamicScheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _resolveColorScheme(
        brightness: Brightness.dark,
        config: config,
        platformDynamicScheme: platformDynamicScheme,
      ),
    );
  }

  static ColorScheme _resolveColorScheme({
    required Brightness brightness,
    required AppThemeConfig config,
    required ColorScheme? platformDynamicScheme,
  }) {
    final usePlatform = config.usePlatformDynamicColors && platformDynamicScheme != null;
    if (usePlatform) {
      return platformDynamicScheme;
    }

    return ColorScheme.fromSeed(
      seedColor: config.seedColor,
      brightness: brightness,
      dynamicSchemeVariant: config.dynamicSchemeVariant,
      contrastLevel: config.contrastLevel,
    );
  }
}