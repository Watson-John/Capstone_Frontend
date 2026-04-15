import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'core/navigation/main_shell.dart';
import 'core/routes/app_routes.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/expense_tracker/presentation/add_expense_page.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/settings/presentation/alias_management_page.dart';
import 'features/settings/presentation/notifications_settings_page.dart';
import 'features/settings/presentation/settings_page.dart';
import 'features/mood_logger/presentation/add_mood_page.dart';
import 'features/todo_list/presentation/add_todo_page.dart';
import 'features/gratitude_journal/presentation/add_gratitude_page.dart';
import 'features/notifications_reminders/presentation/notifications_page.dart';
import 'core/widgets/expressive_squiggle_demo.dart';

class LifelogApp extends StatefulWidget {
  const LifelogApp({
    super.key,
    this.themeConfig = AppThemeConfig.fallback,
    required this.initialRoute,
  });

  final AppThemeConfig themeConfig;
  final String initialRoute;

  @override
  State<LifelogApp> createState() => _LifelogAppState();
}

class _LifelogAppState extends State<LifelogApp> {
  late GlobalKey<NavigatorState> _navigatorKey;

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();

    // Listen for notification tap routes
    pendingRoute.addListener(_handlePendingRoute);

    // Handle any pending route set before listener was attached
    // (e.g., notification tapped while app was closed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingRoute();
    });
  }

  @override
  void dispose() {
    pendingRoute.removeListener(_handlePendingRoute);
    super.dispose();
  }

  void _handlePendingRoute() {
    final route = pendingRoute.value;
    if (route != null) {
      final navigator = _navigatorKey.currentState;
      if (navigator != null) {
        debugPrint('Navigating to pending route: $route');
        pendingRoute.value = null; // Clear after consuming
        navigator.pushNamed(route);
      } else {
        debugPrint('Pending route set but navigator not ready yet: $route');
        // Retry after a short delay
        Future.delayed(const Duration(milliseconds: 500), _handlePendingRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Lifelog',
          theme: AppTheme.light(
            config: widget.themeConfig,
            platformDynamicScheme: lightDynamic,
          ),
          darkTheme: AppTheme.dark(
            config: widget.themeConfig,
            platformDynamicScheme: darkDynamic,
          ),
          themeMode: widget.themeConfig.themeMode,
          initialRoute: widget.initialRoute,
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
            AppRoutes.addExpense: (context) => const AddExpensePage(),
            AppRoutes.addTodo: (context) => const AddTodoPage(),
            AppRoutes.addMood: (context) => const AddMoodPage(),
            AppRoutes.notifications: (context) => const NotificationsPage(),
            AppRoutes.squiggleDemo: (context) =>
                const ExpressiveSquiggleDemoPage(),
            AppRoutes.aliasManagement: (context) =>
                const AliasManagementPage(),
            AppRoutes.notificationsSettings: (context) =>
                const NotificationsSettingsPage(),
            AppRoutes.addGratitude: (context) =>
                const AddGratitudePage(),
          },
        );
      },
    );
  }
}
