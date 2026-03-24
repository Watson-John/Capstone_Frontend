import 'package:flutter/material.dart';

import '../../domain/models/category_styles.dart';

class ReceiptSpendBar extends StatelessWidget {
  const ReceiptSpendBar({
    super.key,
    required this.categories,
    required this.total,
    required this.selectedCategories,
  });

  final List<MapEntry<String, double>> categories;
  final double total;
  final Set<String> selectedCategories;

  @override
  Widget build(BuildContext context) {
    if (total <= 0 || categories.isEmpty) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            const gapWidth = 2.0;
            final totalGaps = (categories.length - 1) * gapWidth;
            final usableWidth = availableWidth - totalGaps;

            return SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (int i = 0; i < categories.length; i++) ...[
                    if (i > 0) const SizedBox(width: gapWidth),
                    _buildSegment(
                      categories[i].key,
                      categories[i].value / total,
                      usableWidth,
                      animValue,
                      isFirst: i == 0,
                      isLast: i == categories.length - 1,
                      dimmed: selectedCategories.isNotEmpty &&
                          !selectedCategories.contains(categories[i].key),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSegment(
    String category,
    double fraction,
    double usableWidth,
    double animValue, {
    required bool isFirst,
    required bool isLast,
    bool dimmed = false,
  }) {
    final style = styleForCategory(category);
    final segWidth =
        (usableWidth * fraction * animValue).clamp(0.0, double.infinity);
    final radius = BorderRadius.horizontal(
      left: isFirst ? const Radius.circular(6) : Radius.zero,
      right: isLast ? const Radius.circular(6) : Radius.zero,
    );

    return AnimatedOpacity(
      opacity: dimmed ? 0.25 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: segWidth,
        height: 12,
        decoration: BoxDecoration(
          color: style.foreground,
          borderRadius: radius,
        ),
      ),
    );
  }
}
