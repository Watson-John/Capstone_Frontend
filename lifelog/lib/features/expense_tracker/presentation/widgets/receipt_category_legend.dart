import 'package:flutter/material.dart';

import '../../domain/models/category_styles.dart';

class ReceiptCategoryLegend extends StatelessWidget {
  const ReceiptCategoryLegend({
    super.key,
    required this.categories,
    required this.total,
    required this.selectedCategories,
    required this.onToggle,
    required this.onToggleAll,
  });

  final List<MapEntry<String, double>> categories;
  final double total;
  final Set<String> selectedCategories;
  final ValueChanged<String> onToggle;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final allKeys = categories.map((e) => e.key).toSet();
    final allSelected = allKeys.isNotEmpty &&
        allKeys.every(selectedCategories.contains);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: _CategoryButton(
            label: 'All',
            amount: total,
            bgColor: Theme.of(context).colorScheme.primary,
            fgColor: Theme.of(context).colorScheme.onPrimary,
            isSelected: allSelected,
            centerText: true,
            invertText: true,
            onTap: onToggleAll,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: categories.map((entry) {
            final style = styleForCategory(entry.key);
            final isSelected =
                selectedCategories.contains(entry.key);
            return _CategoryButton(
              label: formatCategoryLabel(entry.key),
              amount: entry.value,
              bgColor: style.background,
              fgColor: style.foreground,
              isSelected: isSelected,
              onTap: () => onToggle(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.amount,
    required this.bgColor,
    required this.fgColor,
    required this.isSelected,
    required this.onTap,
    this.centerText = false,
    this.invertText = false,
  });

  final String label;
  final double amount;
  final Color bgColor;
  final Color fgColor;
  final bool isSelected;
  final VoidCallback onTap;
  final bool centerText;
  final bool invertText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelColor = invertText ? fgColor : cs.onSurface;
    final amountColor =
        invertText ? fgColor.withValues(alpha: 0.8) : cs.onSurfaceVariant;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: fgColor.withValues(alpha: 0.12),
        highlightColor: fgColor.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? fgColor : bgColor,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                centerText ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: amountColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
