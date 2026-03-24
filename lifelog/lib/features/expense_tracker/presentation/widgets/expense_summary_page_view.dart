import 'package:flutter/material.dart';

import 'category_breakdown_card.dart';
import 'expense_summary_card.dart';

class ExpenseSummaryPageView extends StatefulWidget {
  const ExpenseSummaryPageView({
    super.key,
    required this.budgetAmount,
    required this.spent,
    required this.categorySpending,
    required this.categoryTotal,
    required this.onEditBudget,
  });

  final double budgetAmount;
  final double spent;
  final List<MapEntry<String, double>> categorySpending;
  final double categoryTotal;
  final VoidCallback onEditBudget;

  @override
  State<ExpenseSummaryPageView> createState() => _ExpenseSummaryPageViewState();
}

class _ExpenseSummaryPageViewState extends State<ExpenseSummaryPageView> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final pageHeight = (constraints.maxWidth * 0.46).clamp(180.0, 260.0);

        return Column(
          children: [
            SizedBox(
              height: pageHeight,
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  ExpenseSummaryCard(
                    budgetAmount: widget.budgetAmount,
                    spent: widget.spent,
                    onEditBudget: widget.onEditBudget,
                  ),
                  CategoryBreakdownCard(
                    categories: widget.categorySpending,
                    total: widget.categoryTotal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) {
                final isActive = _page == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? cs.primary : cs.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
