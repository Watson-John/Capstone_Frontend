import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/services/notification_service.dart';
import '../../expense_tracker/domain/models/expense.dart';
import '../../expense_tracker/domain/models/budget.dart';
import '../../mood_logger/domain/models/mood_log.dart';
import '../../todo_list/domain/models/todo_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userName = '';
  String _dailyQuote = '';
  bool _isLoadingQuote = true;

  int _todoCount = 0;
  double _totalSpent = 0;
  String _lastMoodEmoji = '';
  String _lastMoodLabel = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchDailyQuote();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
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
      _userName = prefs.getString('userName') ?? 'User';
      _todoCount = activeTodos;
      _totalSpent = spent;
      _lastMoodEmoji = lastMood?.emoji ?? '';
      _lastMoodLabel = lastMood?.mood ?? 'None yet';
    });
  }

  Future<void> _fetchDailyQuote() async {
    final quote = await NotificationService().getDailyQuote();
    if (mounted) {
      setState(() {
        _dailyQuote = quote;
        _isLoadingQuote = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildGreeting(context),
              const SizedBox(height: 24),
              _buildQuickStats(context),
              const SizedBox(height: 20),
              _buildQuoteCard(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Greeting ───────────────────────────────────────────────────────────────

  Widget _buildGreeting(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello,',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _userName,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  // ── Quick stats row ────────────────────────────────────────────────────────

  Widget _buildQuickStats(BuildContext context) {
    final moodDisplay = _lastMoodEmoji.isNotEmpty
        ? '$_lastMoodEmoji  $_lastMoodLabel'
        : _lastMoodLabel;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.checklist_rounded,
            label: 'Active Tasks',
            value: '$_todoCount',
            accentColor: AppTheme.cardToDoBg,
            iconColor: AppTheme.accentAmber,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Spent',
            value: '\$${_totalSpent.toStringAsFixed(0)}',
            accentColor: AppTheme.cardSpentBg,
            iconColor: AppTheme.accentRed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
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

  // ── Quote card ─────────────────────────────────────────────────────────────

  Widget _buildQuoteCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Quote of the Day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoadingQuote
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.primary),
                  ),
                )
              : Text(
                  '"$_dailyQuote"',
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface,
                    height: 1.5,
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor != null ? accentColor : accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.onSurface, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
