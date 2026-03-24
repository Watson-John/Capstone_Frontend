import 'package:flutter/material.dart';

import '../../domain/models/category_styles.dart';
import 'category_spend_bar.dart';

class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({
    super.key,
    required this.categories,
    required this.total,
  });

  final List<MapEntry<String, double>> categories;
  final double total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: categories.isEmpty
          ? Center(
              child: Text(
                'No category data yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spending by Category',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                ),
                const SizedBox(height: 12),
                CategorySpendBar(categories: categories, total: total),
                const SizedBox(height: 12),
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white, Colors.white.withValues(alpha: 0)],
                      stops: const [0.0, 0.85, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((entry) {
                          final style = styleForCategory(entry.key);
                          final pct = total > 0
                              ? (entry.value / total * 100)
                                  .toStringAsFixed(0)
                              : '0';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: style.background,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: style.foreground,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formatCategoryLabel(entry.key),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: style.foreground,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '\$${entry.value.toStringAsFixed(2)} ($pct%)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: style.foreground
                                            .withValues(alpha: 0.7),
                                      ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
