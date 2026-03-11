import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../data/expense_service.dart';
import '../domain/models/budget.dart';
import '../domain/models/expense.dart';
import 'widgets/budget_card.dart';
import 'widgets/scan_button.dart';

class ExpenseTrackerPage extends StatefulWidget {
  const ExpenseTrackerPage({super.key});

  @override
  State<ExpenseTrackerPage> createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage> {
  final _service = ExpenseService();
  List<Expense> _expenses = [];
  Budget? _budget;
  double _periodSpent = 0;
  bool _isScanning = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final db = DatabaseHelper();
    final results = await Future.wait([db.getExpenses(), db.getBudget()]);
    if (!mounted) return;
    final expenses = results[0] as List<Expense>;
    final budget = results[1] as Budget?;
    setState(() {
      _expenses = expenses;
      _budget = budget;
      _isLoading = false;
    });
    _recalcPeriodSpent(expenses, budget);
  }

  void _recalcPeriodSpent(List<Expense> expenses, Budget? budget) {
    if (budget == null) return;
    final now = DateTime.now();
    final start = budget.currentPeriodStart(now);
    // Filter by createdAt (when the expense was logged), not the receipt's
    // printed date. Scanning an old receipt today should count against the
    // current period budget.
    final spent = expenses.where((e) {
      final logged = DateTime.tryParse(e.createdAt);
      if (logged == null) return false;
      return !logged.isBefore(start) && !logged.isAfter(now);
    }).fold(0.0, (sum, e) => sum + e.amount);
    if (mounted) setState(() => _periodSpent = spent);
  }

  Future<void> _onImageCaptured(XFile image) async {
    setState(() => _isScanning = true);
    try {
      final result = await _service.scanReceipt(File(image.path));
      if (!mounted) return;
      final saved = await Navigator.of(context).pushNamed(
        AppRoutes.addExpense,
        arguments: result,
      );
      if (saved == true) _loadAll();
    } on ExpenseScanException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
      debugPrint('[ExpenseTrackerPage] scan error: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scan Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    if (expense.id == null) return;
    await DatabaseHelper().deleteExpense(expense.id!);
    _loadAll();
  }

  Future<void> _showBudgetDialog([Budget? existing]) async {
    final amountController = TextEditingController(
      text: existing != null ? existing.limitAmount.toStringAsFixed(2) : '',
    );
    var period = existing?.period ?? BudgetPeriod.monthly;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Set Spending Budget' : 'Edit Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Spending Limit',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              SegmentedButton<BudgetPeriod>(
                segments: const [
                  ButtonSegment(
                    value: BudgetPeriod.monthly,
                    label: Text('Monthly'),
                    icon: Icon(Icons.calendar_month_outlined),
                  ),
                  ButtonSegment(
                    value: BudgetPeriod.biweekly,
                    label: Text('Bi-weekly'),
                    icon: Icon(Icons.date_range_outlined),
                  ),
                ],
                selected: {period},
                onSelectionChanged: (s) =>
                    setDialogState(() => period = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final raw = amountController.text.replaceAll(',', '').trim();
                final amount = double.tryParse(raw);
                if (amount == null || amount <= 0) return;
                final newBudget = Budget(
                  id: existing?.id,
                  limitAmount: amount,
                  period: period,
                  createdAt: DateTime.now().toIso8601String(),
                );
                await DatabaseHelper().saveBudget(newBudget);
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildContent(context),

        // Scanning overlay
        if (_isScanning)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Scanning receipt\u2026',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

        // Scan FAB
        Align(
          alignment: Alignment.bottomRight,
          child: SafeArea(
            minimum: const EdgeInsets.only(right: 20, bottom: 24),
            child: ScanButton(
              onImageCaptured: _isScanning ? null : _onImageCaptured,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final budgetWidget = _budget != null
        ? BudgetCard(
            budget: _budget!,
            spent: _periodSpent,
            onEdit: () => _showBudgetDialog(_budget),
          )
        : _SetBudgetBanner(onTap: () => _showBudgetDialog());

    if (_expenses.isEmpty) {
      return Column(
        children: [
          budgetWidget,
          Expanded(child: _buildEmptyState(context)),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: _expenses.length + 1, // index 0 = budget widget
      itemBuilder: (context, index) {
        if (index == 0) return budgetWidget;
        final expense = _expenses[index - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ExpenseCard(
            expense: expense,
            onDelete: () => _deleteExpense(expense),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            'No expenses yet',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the scan button to add one',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Set Budget Banner ─────────────────────────────────────────────────────────

class _SetBudgetBanner extends StatelessWidget {
  const _SetBudgetBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.savings_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set a spending budget',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: colorScheme.primary),
                    ),
                    Text(
                      'Track expenses against a monthly or bi-weekly limit',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Expense Card ──────────────────────────────────────────────────────────────

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expense, required this.onDelete});

  final Expense expense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.receipt_outlined,
              color: colorScheme.onPrimaryContainer, size: 20),
        ),
        title: Text(expense.vendor, style: theme.textTheme.titleSmall),
        subtitle: Text(
          '${expense.category} \u00b7 ${expense.date}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
