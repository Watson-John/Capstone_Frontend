import 'package:flutter/material.dart';

import '../../domain/models/category_styles.dart';
import '../../domain/models/receipt_line_item.dart';

class ReceiptItemsList extends StatelessWidget {
  const ReceiptItemsList({
    super.key,
    required this.items,
    required this.sortedCategories,
    required this.selectedCategories,
    required this.onRecategorize,
  });

  final List<ReceiptLineItem> items;
  final List<MapEntry<String, double>> sortedCategories;
  final Set<String> selectedCategories;
  final ValueChanged<ReceiptLineItem> onRecategorize;

  @override
  Widget build(BuildContext context) {
    if (selectedCategories.isEmpty) {
      return _buildPlaceholder(context);
    }

    final selectedCats = sortedCategories
        .where((e) => selectedCategories.contains(e.key))
        .toList();

    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int ci = 0; ci < selectedCats.length; ci++) ...[
            if (ci > 0) const SizedBox(height: 8),
            Builder(builder: (context) {
              final catEntry = selectedCats[ci];
              final style = styleForCategory(catEntry.key);
              final catItems = items
                  .where((i) => i.category == catEntry.key)
                  .toList()
                ..sort((a, b) => b.price.compareTo(a.price));
              final categoryTotal =
                  catItems.fold(0.0, (s, i) => s + i.price);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: style.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formatCategoryLabel(catEntry.key),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Text(
                              '\$${categoryTotal.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: style.foreground,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Column(
                      children: catItems
                          .map((item) =>
                              _buildItemRow(context, item, style))
                          .toList(),
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.touch_app_outlined,
              size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'Tap a category above to see its items',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    ReceiptLineItem item,
    CategoryStyle style,
  ) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onRecategorize(item),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: style.foreground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.decodedName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                  ),
                  if (item.isUncategorized)
                    Text(
                      'Tap to categorize',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFE65100),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '\$${item.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined,
                size: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
