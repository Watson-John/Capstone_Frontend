import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'core/navigation/main_shell.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/settings/presentation/settings_page.dart';
import 'features/todo_list/presentation/add_todo_page.dart';
import 'features/notifications_reminders/presentation/notifications_page.dart';

class LifelogApp extends StatelessWidget {
  const LifelogApp({
    super.key,
    this.themeConfig = AppThemeConfig.fallback,
    required this.initialRoute,
  });

  final AppThemeConfig themeConfig;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Lifelog',
          theme: AppTheme.light(
            config: themeConfig,
            platformDynamicScheme: lightDynamic,
          ),
          darkTheme: AppTheme.dark(
            config: themeConfig,
            platformDynamicScheme: darkDynamic,
          ),
          themeMode: themeConfig.themeMode,
          initialRoute: initialRoute,
          routes: {
            AppRoutes.onboarding: (context) => const OnboardingPage(),
            AppRoutes.dashboard: (context) => const MainShell(initialIndex: 2),
            AppRoutes.expenseTracker: (context) =>
                const MainShell(initialIndex: 1),
            AppRoutes.moodLogger: (context) => const MainShell(initialIndex: 3),
            AppRoutes.gratitudeJournal: (context) =>
                const MainShell(initialIndex: 4),
            AppRoutes.todoList: (context) => const MainShell(initialIndex: 0),
            AppRoutes.settings: (context) => const SettingsPage(),
            AppRoutes.addTodo: (context) => const AddTodoPage(),
            AppRoutes.notifications: (context) => const NotificationsPage(),
          },
        );
      },
    );
  }
}
