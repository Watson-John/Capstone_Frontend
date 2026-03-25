import 'package:flutter/material.dart';

import '../../domain/models/category_styles.dart';
import '../../domain/models/expense.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.expense,
    required this.onTap,
    this.lineItemCategories,
  });

  final Expense expense;
  final VoidCallback onTap;
  final Set<String>? lineItemCategories;

  String get _effectiveCategory {
    final cats = lineItemCategories;
    if (cats == null || cats.isEmpty) return expense.category;
    if (cats.length == 1) return cats.first;
    return 'MIXED';
  }

  static IconData _icon(String category) {
    switch (category) {
      case 'DINING':
        return Icons.dinner_dining;
      case 'GROCERY':
        return Icons.local_grocery_store;
      case 'KIDS':
        return Icons.toys;
      case 'FUEL_AUTO':
        return Icons.local_gas_station;
      case 'HOUSEHOLD':
        return Icons.home_outlined;
      case 'BEAUTY_CARE':
        return Icons.spa_outlined;
      case 'PHARMACY':
        return Icons.local_pharmacy_outlined;
      case 'CLOTHING':
        return Icons.checkroom_outlined;
      case 'BOOKS_OFFICE':
        return Icons.menu_book_outlined;
      case 'ELECTRONICS':
        return Icons.devices_outlined;
      case 'HOME_DECOR':
        return Icons.chair_outlined;
      case 'PET_SUPPLIES':
        return Icons.pets;
      case 'TRAVEL':
        return Icons.flight_outlined;
      case 'FEES_TAX':
        return Icons.account_balance_outlined;
      case 'OTHER':
        return Icons.category_outlined;
      case 'UNCATEGORIZED':
        return Icons.help_outline;
      case 'MIXED':
        return Icons.shuffle;
      default:
        return Icons.receipt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveCat = _effectiveCategory;
    final isScanned = expense.veryfiDocumentId != null;
    final catStyle = styleForCategory(effectiveCat);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Category badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: catStyle.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_icon(effectiveCat), color: const Color(0xFF1C1C1C), size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Vendor + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.vendor,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expense.date,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount
                  Text(
                    '-\$${expense.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
            ),
            // Source badge — top-right corner
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isScanned
                      ? Icons.document_scanner_outlined
                      : Icons.edit_outlined,
                  size: 14,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
