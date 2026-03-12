import 'package:flutter/material.dart';

/// Unified primary action FAB used across all feature pages.
///
/// Colors are sourced from [FloatingActionButtonThemeData] set globally in
/// [AppTheme.light], so no hard-coded values are needed here.
class AppFab extends StatelessWidget {
  const AppFab({super.key, required this.onPressed, required this.heroTag});

  final VoidCallback? onPressed;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        tooltip: 'Add',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
