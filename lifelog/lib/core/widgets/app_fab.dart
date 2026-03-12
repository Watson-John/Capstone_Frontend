import 'package:flutter/material.dart';

/// Unified primary action FAB used across all feature pages.
///
/// Colors are sourced from [FloatingActionButtonThemeData] set globally in
/// [AppTheme.light], so no hard-coded values are needed here.
class AppFab extends StatelessWidget {
  const AppFab({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: 'Add',
      child: const Icon(Icons.add),
    );
  }
}
