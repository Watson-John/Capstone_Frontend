import 'package:flutter/material.dart';

import '../../domain/models/category_styles.dart';

class CategorySpendBar extends StatelessWidget {
  const CategorySpendBar({
    super.key,
    required this.categories,
    required this.total,
  });

  final List<MapEntry<String, double>> categories;
  final double total;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

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
                    Builder(builder: (context) {
                      final style = styleForCategory(categories[i].key);
                      final segWidth = (usableWidth *
                              (categories[i].value / total) *
                              animValue)
                          .clamp(0.0, double.infinity);
                      final radius = BorderRadius.horizontal(
                        left:
                            i == 0 ? const Radius.circular(6) : Radius.zero,
                        right: i == categories.length - 1
                            ? const Radius.circular(6)
                            : Radius.zero,
                      );
                      return Container(
                        width: segWidth,
                        height: 12,
                        decoration: BoxDecoration(
                          color: style.foreground,
                          borderRadius: radius,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
