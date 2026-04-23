import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../expense_tracker/domain/models/budget.dart';
import '../../../expense_tracker/domain/models/expense.dart';
import '../../../expense_tracker/presentation/widgets/expense_summary_card.dart';

/// Self-fetching card that renders a budget overview for the dashboard.
class DashboardBudgetCard extends StatefulWidget {
  const DashboardBudgetCard({super.key});

  @override
  State<DashboardBudgetCard> createState() => _DashboardBudgetCardState();
}

class _DashboardBudgetCardState extends State<DashboardBudgetCard> {
  bool _isLoading = true;
  Budget? _budget;
  double _spent = 0;
  int _thresholdPct = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper();
    final prefs = await SharedPreferences.getInstance();
    final results = await Future.wait([db.getBudget(), db.getExpenses()]);
    if (!mounted) return;

    final budget = results[0] as Budget?;
    final expenses = results[1] as List<Expense>;

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

    setState(() {
      _budget = budget;
      _spent = spent;
      _thresholdPct = prefs.getInt(kBudgetThresholdKey) ?? 20;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_budget == null) {
      return _NoBudgetPlaceholder(onLoad: _load);
    }

    return ExpenseSummaryCard(
      budgetAmount: _budget!.limitAmount,
      spent: _spent,
      onEditBudget: () {},
      alertThresholdPct: _thresholdPct,
    );
  }
}

class _NoBudgetPlaceholder extends StatelessWidget {
  const _NoBudgetPlaceholder({required this.onLoad});
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              color: cs.onSurfaceVariant, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No budget set yet.\nHead to Expenses to add one.',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
