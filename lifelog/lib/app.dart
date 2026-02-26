import 'package:flutter/material.dart';

import 'core/navigation/main_shell.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/settings/presentation/settings_page.dart';

class LifelogApp extends StatelessWidget {
  const LifelogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lifelog',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: AppTheme.mode,
      initialRoute: AppRoutes.onboarding,
      routes: {
        AppRoutes.onboarding: (context) => const OnboardingPage(),
        AppRoutes.dashboard: (context) => const MainShell(initialIndex: 2),
        AppRoutes.expenseTracker: (context) => const MainShell(initialIndex: 1),
        AppRoutes.moodLogger: (context) => const MainShell(initialIndex: 3),
        AppRoutes.gratitudeJournal: (context) => const MainShell(initialIndex: 4),
        AppRoutes.todoList: (context) => const MainShell(initialIndex: 0),
        AppRoutes.settings: (context) => const SettingsPage(),
      },
    );
  }
}
