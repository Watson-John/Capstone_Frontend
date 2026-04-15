import 'package:flutter/material.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../expense_tracker/domain/models/budget.dart';
import '../../../expense_tracker/domain/models/expense.dart';
import '../../../mood_logger/domain/models/mood_log.dart';
import '../../../todo_list/domain/models/todo_model.dart';
import 'dashboard_stat_card.dart';

/// Self-fetching card that shows Active Tasks, Spent, and Last Mood.
class DashboardQuickStatsCard extends StatefulWidget {
  const DashboardQuickStatsCard({super.key});

  @override
  State<DashboardQuickStatsCard> createState() =>
      _DashboardQuickStatsCardState();
}

class _DashboardQuickStatsCardState extends State<DashboardQuickStatsCard> {
  bool _isLoading = true;
  int _todoCount = 0;
  double _totalSpent = 0;
  String _lastMoodEmoji = '';
  String _lastMoodLabel = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper();
    final results = await Future.wait([
      db.getTodos(),
      db.getExpenses(),
      db.getMoodLogs(),
      db.getBudget(),
    ]);
    if (!mounted) return;

    final todos = results[0] as List<Todo>;
    final expenses = results[1] as List<Expense>;
    final moods = results[2] as List<MoodLog>;
    final budget = results[3] as Budget?;

    final activeTodos = todos.where((t) => t.status != 'Completed').length;

    double spent = 0;
    if (budget != null) {
      final now = DateTime.now();
      final start = budget.currentPeriodStart(now);
      spent = expenses.where((e) {
        final logged = DateTime.tryParse(e.createdAt);
        return logged != null &&
            !logged.isBefore(start) &&
            !logged.isAfter(now);
      }).fold(0.0, (s, e) => s + e.amount);
    } else {
      spent = expenses.fold(0.0, (s, e) => s + e.amount);
    }

    final lastMood = moods.isNotEmpty ? moods.first : null;

    setState(() {
      _todoCount = activeTodos;
      _totalSpent = spent;
      _lastMoodEmoji = lastMood?.emoji ?? '';
      _lastMoodLabel = lastMood?.mood ?? 'None yet';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final moodDisplay = _lastMoodEmoji.isNotEmpty
        ? '$_lastMoodEmoji  $_lastMoodLabel'
        : _lastMoodLabel;

    return Row(
      children: [
        Expanded(
          child: DashboardStatCard(
            icon: Icons.checklist_rounded,
            label: 'Active Tasks',
            value: '$_todoCount',
            accentColor: AppTheme.cardTotalBg,
            iconColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DashboardStatCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Spent',
            value: '\$${_totalSpent.toStringAsFixed(0)}',
            accentColor: AppTheme.cardSpentBg,
            iconColor: AppTheme.accentRed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DashboardStatCard(
            icon: Icons.mood_outlined,
            label: 'Last Mood',
            value: moodDisplay,
            accentColor: AppTheme.cardCompletedBg,
            iconColor: AppTheme.accentGreen,
          ),
        ),
      ],
    );
  }
}
