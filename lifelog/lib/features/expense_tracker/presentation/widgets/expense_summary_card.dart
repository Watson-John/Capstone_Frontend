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
    this.alertThresholdPct = 20,
  });

  final double budgetAmount;
  final double spent;
  final VoidCallback onEditBudget;
  final int alertThresholdPct;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Compute remaining % to determine indicator state.
    final remainingPct = budgetAmount > 0
        ? ((budgetAmount - spent) / budgetAmount * 100).round()
        : 100;
    final cautionThreshold = alertThresholdPct + 10;
    final isAlert = remainingPct <= alertThresholdPct;
    final isCaution = !isAlert && remainingPct <= cautionThreshold;

    Widget? indicator;
    if (isAlert) {
      indicator = _BudgetIndicator(
        icon: Icons.error_outline,
        color: Colors.red.shade600,
        label: '!',
      );
    } else if (isCaution) {
      indicator = _BudgetIndicator(
        icon: Icons.warning_amber_rounded,
        color: Colors.amber.shade700,
        label: '⚠',
      );
    }

    return Stack(
      children: [
        Container(
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
        ),
        if (indicator != null)
          Positioned(top: 8, right: 8, child: indicator),
      ],
    );
  }
}

class _BudgetIndicator extends StatelessWidget {
  const _BudgetIndicator({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
