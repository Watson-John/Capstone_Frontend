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
    seedColor: Color(0xFF1F4A7A),
    themeMode: ThemeMode.light,
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

/// Semantic app colors that sit on top of Material ColorScheme.
///
/// Keep this as the single source of truth for dashboard/task/expense accents
/// so widgets can inherit it from ThemeData instead of hardcoding colors.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.cardTotalBg,
    required this.cardToDoBg,
    required this.cardInProgressBg,
    required this.cardCompletedBg,
    required this.cardSpentBg,
    required this.statCardText,
    required this.cardChildBg,
    required this.accentGreen,
    required this.accentRed,
    required this.accentAmber,
  });

  static const AppSemanticColors light = AppSemanticColors(
    cardTotalBg: Color(0xFFD9EBFA),
    cardToDoBg: Color(0xFFFFCCCC),
    cardInProgressBg: Color(0xFFFFF0BE),
    cardCompletedBg: Color(0xFFCCEDD8),
    cardSpentBg: Color(0xFFFFD5CE),
    statCardText: Color(0xFF1C1C1C),
    cardChildBg: Color(0xFFEDE6DA),
    accentGreen: Color(0xFF5E9980),
    accentRed: Color(0xFFAD6464),
    accentAmber: Color(0xFFC07A1A),
  );

  final Color cardTotalBg;
  final Color cardToDoBg;
  final Color cardInProgressBg;
  final Color cardCompletedBg;
  final Color cardSpentBg;
  final Color statCardText;
  final Color cardChildBg;
  final Color accentGreen;
  final Color accentRed;
  final Color accentAmber;

  @override
  AppSemanticColors copyWith({
    Color? cardTotalBg,
    Color? cardToDoBg,
    Color? cardInProgressBg,
    Color? cardCompletedBg,
    Color? cardSpentBg,
    Color? statCardText,
    Color? cardChildBg,
    Color? accentGreen,
    Color? accentRed,
    Color? accentAmber,
  }) {
    return AppSemanticColors(
      cardTotalBg: cardTotalBg ?? this.cardTotalBg,
      cardToDoBg: cardToDoBg ?? this.cardToDoBg,
      cardInProgressBg: cardInProgressBg ?? this.cardInProgressBg,
      cardCompletedBg: cardCompletedBg ?? this.cardCompletedBg,
      cardSpentBg: cardSpentBg ?? this.cardSpentBg,
      statCardText: statCardText ?? this.statCardText,
      cardChildBg: cardChildBg ?? this.cardChildBg,
      accentGreen: accentGreen ?? this.accentGreen,
      accentRed: accentRed ?? this.accentRed,
      accentAmber: accentAmber ?? this.accentAmber,
    );
  }

  @override
  AppSemanticColors lerp(
      covariant ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      cardTotalBg: Color.lerp(cardTotalBg, other.cardTotalBg, t)!,
      cardToDoBg: Color.lerp(cardToDoBg, other.cardToDoBg, t)!,
      cardInProgressBg:
          Color.lerp(cardInProgressBg, other.cardInProgressBg, t)!,
      cardCompletedBg:
          Color.lerp(cardCompletedBg, other.cardCompletedBg, t)!,
      cardSpentBg: Color.lerp(cardSpentBg, other.cardSpentBg, t)!,
      statCardText: Color.lerp(statCardText, other.statCardText, t)!,
      cardChildBg: Color.lerp(cardChildBg, other.cardChildBg, t)!,
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t)!,
      accentRed: Color.lerp(accentRed, other.accentRed, t)!,
      accentAmber: Color.lerp(accentAmber, other.accentAmber, t)!,
    );
  }
}

class AppTheme {
  // ── Base Theme Colors ────────────────────────────────────────────────────
  static const _surface          = Color(0xFFF6F1EA); // warm linen — gentle cream, not too orange, not too cold
  static const _surfaceContainer = Color(0xFFFFFFFF);                  // Level 1 Base Cards: pure white
  static const _semantic         = AppSemanticColors.light;
  static const _primary          = Color(0xFF1F4A7A);                  // Softer navy blue
  static const _onPrimary        = Color(0xFFFFFFFF);
  static const _primaryContainer = Color(0xFFD8E9F5);                  // Very light blue – active tab indicator
  static const _onSurface        = Color(0xFF1C1C1C);                  // Near-black universal text
  static const _secondary        = Color(0xFF3D5A80);                  // Slate blue (icons/non-text only)
  static const _outline          = Color(0xFFBDBDBD);                  // Neutral grey border

  // ── Semantic Stat/Card Colors (legacy API, now backed by AppSemanticColors)
  static Color get cardTotalBg => _semantic.cardTotalBg;
  static Color get cardTotalText => _semantic.statCardText;
  static Color get cardToDoBg => _semantic.cardToDoBg;
  static Color get cardToDoText => _semantic.statCardText;
  static Color get cardInProgressBg => _semantic.cardInProgressBg;
  static Color get cardInProgressText => _semantic.statCardText;
  static Color get cardCompletedBg => _semantic.cardCompletedBg;
  static Color get cardCompletedText => _semantic.statCardText;
  static Color get cardSpentBg => _semantic.cardSpentBg;
  static Color get cardSpentText => _semantic.statCardText;

  // ── Level 2 child element background ──────────────────────────────────────
  // Used for: task timeline items, inactive calendar circles, mood log rows
  static Color get cardChildBg => _semantic.cardChildBg;

  // ── Decorative accent colors (charts, dots, status stripes — NOT text) ─────
  static Color get accentGreen => _semantic.accentGreen;
  static Color get accentRed => _semantic.accentRed;
  static Color get accentAmber => _semantic.accentAmber;

  static ColorScheme _navyBlueScheme() {
    // Use fromSeed for derived tones, then copyWith the exact spec values.
    return ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
    ).copyWith(
      surface: _surface,
      surfaceContainer: _surfaceContainer,
      surfaceContainerHighest: cardChildBg, // Level 2 child bg (mood rows, notes containers)
      primary: _primary,
      onPrimary: _onPrimary,
      primaryContainer: _primaryContainer,
      onPrimaryContainer: _onSurface,        // Near-black on light-blue container
      onSurface: _onSurface,
      onSurfaceVariant: const Color(0xFF4A4A4A), // Dark charcoal for supporting text
      secondary: _secondary,
      outline: _outline,
    );
  }

  static ThemeData light({
    required AppThemeConfig config,
    ColorScheme? platformDynamicScheme,
  }) {
    final cs = _navyBlueScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      extensions: const <ThemeExtension<dynamic>>[
        AppSemanticColors.light,
      ],
      scaffoldBackgroundColor: cs.surface,

      // ── Cards ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: cs.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Bottom NavigationBar ───────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary);
          }
          return IconThemeData(color: cs.onSurfaceVariant);
        }),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
        actionsIconTheme: IconThemeData(color: cs.onSurface),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Inputs ─────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        filled: true,
        fillColor: cs.surface,
      ),

      // ── Dividers ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
      ),

      // ── Bottom sheets ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // ── Dialogs ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      // ── Snack bars ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.inverseSurface,
        contentTextStyle: TextStyle(color: cs.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Buttons ────────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: cs.primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return cs.primaryContainer;
            }
            return cs.surfaceContainer;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return cs.onPrimaryContainer;
            }
            return cs.onSurfaceVariant;
          }),
        ),
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
    final usePlatform =
        config.usePlatformDynamicColors && platformDynamicScheme != null;
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
