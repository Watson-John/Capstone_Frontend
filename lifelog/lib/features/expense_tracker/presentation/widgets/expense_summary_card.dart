import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'donut_painter.dart';
import 'summary_item.dart';

class ExpenseSummaryCard extends StatelessWidget {
  const ExpenseSummaryCard({
    super.key,
    required this.budgetAmount,
    required this.spent,
    required this.onEditBudget,
  });

  final double budgetAmount;
  final double spent;
  final VoidCallback onEditBudget;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SummaryItem(
                  label: 'Spending Limit',
                  amount: budgetAmount,
                  dotColor: AppTheme.accentGreen,
                  onEditTap: onEditBudget,
                ),
                const SizedBox(height: 12),
                SummaryItem(
                  label: 'Spent',
                  amount: spent,
                  dotColor: AppTheme.accentRed,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = (constraints.maxHeight * 0.82).clamp(64.0, 110.0);
              return SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: DonutPainter(
                    spent: spent,
                    total: budgetAmount,
                    spentColor: AppTheme.accentRed,
                    remainColor: AppTheme.accentGreen,
                    trackColor: cs.outlineVariant,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
