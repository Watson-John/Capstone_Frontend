import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/expense_tracker/presentation/expense_tracker_page.dart';
import '../../features/gratitude_journal/presentation/gratitude_journal_page.dart';
import '../../features/mood_logger/presentation/mood_logger_page.dart';
import '../../features/todo_list/presentation/todo_list_page.dart';
import '../database/database_helper.dart';
import '../routes/app_routes.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 2});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  int _unreadCount = 0;
  late final StreamSubscription<dynamic> _messageSub;

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
    _refreshUnreadCount();
    _messageSub = FirebaseMessaging.onMessage.listen((_) => _refreshUnreadCount());
  }

  @override
  void dispose() {
    _messageSub.cancel();
    super.dispose();
  }

  Future<void> _refreshUnreadCount() async {
    final count = await DatabaseHelper().getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16.0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(Icons.volunteer_activism, color: const Color(0xFF8A4F00), size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Lifelog',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none, size: 28, color: cs.onSurface),
                onPressed: () async {
                  await Navigator.of(context).pushNamed(AppRoutes.notifications);
                  _refreshUnreadCount();
                },
                tooltip: 'Notifications',
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                      style: TextStyle(
                        color: cs.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.menu, size: 28, color: cs.onSurface),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
            tooltip: 'Settings / Menu',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Material(
                elevation: 3,
                color: cs.surfaceContainer,
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
                  backgroundColor: cs.surfaceContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
