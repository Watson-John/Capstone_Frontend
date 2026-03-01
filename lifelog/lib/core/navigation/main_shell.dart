import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/expense_tracker/presentation/expense_tracker_page.dart';
import '../../features/gratitude_journal/presentation/gratitude_journal_page.dart';
import '../../features/mood_logger/presentation/mood_logger_page.dart';
import '../../features/todo_list/presentation/todo_list_page.dart';
import '../routes/app_routes.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 2});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist),
      label: 'To-Do',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: 'Expenses',
    ),
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.mood_outlined),
      selectedIcon: Icon(Icons.mood),
      label: 'Mood',
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite),
      label: 'Gratitude',
    ),
  ];

  static const _pages = <Widget>[
    TodoListPage(),
    ExpenseTrackerPage(),
    DashboardPage(),
    MoodLoggerPage(),
    GratitudeJournalPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF3EDCE), // Match beige background globally
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16.0, // Match horizontal padding
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: const Icon(Icons.volunteer_activism, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text(
              'Lifelog',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, size: 32, color: Color(0xFF3B4863)),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.settings),
            tooltip: 'Settings / Menu',
          ),
          const SizedBox(width: 8), // Padding on right
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(6, 0, 6, 16),
        child: Material(
          elevation: 3,
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: _destinations,
            backgroundColor: theme.colorScheme.surfaceContainer,
          ),
        ),
      ),
    );
  }
}
