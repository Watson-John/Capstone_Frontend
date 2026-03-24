import 'package:flutter/material.dart';

import '../../domain/models/expense.dart';
import 'transaction_row.dart';

class ExpenseTransactionsSection extends StatelessWidget {
  const ExpenseTransactionsSection({
    super.key,
    required this.expenses,
    required this.showAll,
    required this.onToggleShowAll,
    required this.onDelete,
    required this.onTap,
  });

  final List<Expense> expenses;
  final bool showAll;
  final VoidCallback onToggleShowAll;
  final ValueChanged<Expense> onDelete;
  final ValueChanged<Expense> onTap;

  @override
  Widget build(BuildContext context) {
    final visible = showAll ? expenses : expenses.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (expenses.length > 5)
              GestureDetector(
                onTap: onToggleShowAll,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Text(
                    showAll ? 'Show Less' : 'See All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // List or empty state
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 52, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'No transactions',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add one',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ...visible.map(
            (expense) => Dismissible(
              key: ValueKey(expense.id ?? expense.createdAt),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.delete_outline, color: Colors.red.shade600),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete transaction?'),
                    content: Text(
                        'Remove "${expense.vendor}" from your expenses?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) => onDelete(expense),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TransactionRow(
                  expense: expense,
                  onTap: () => onTap(expense),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
