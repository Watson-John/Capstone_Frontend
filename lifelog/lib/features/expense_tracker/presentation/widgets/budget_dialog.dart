import 'package:flutter/material.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/models/budget.dart';

Future<bool?> showBudgetDialog(BuildContext context, {Budget? existing}) {
  final amountController = TextEditingController(
    text: existing != null ? existing.limitAmount.toStringAsFixed(2) : '',
  );
  var period = existing?.period ?? BudgetPeriod.monthly;

  return showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Set Spending Limit' : 'Edit Spending Limit'),
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
}
