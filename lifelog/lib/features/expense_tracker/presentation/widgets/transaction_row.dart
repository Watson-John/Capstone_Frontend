import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/expense.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.expense, required this.onTap});

  final Expense expense;
  final VoidCallback onTap;

  static IconData _icon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'meals & entertainment':
        return Icons.restaurant_outlined;
      case 'salary':
      case 'income':
        return Icons.attach_money;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'shopping':
      case 'retail':
        return Icons.shopping_bag_outlined;
      case 'transport':
      case 'transportation':
        return Icons.directions_car_outlined;
      case 'utilities':
        return Icons.bolt_outlined;
      case 'health':
      case 'medical':
        return Icons.favorite_border;
      default:
        return Icons.receipt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = expense.category;
    final isScanned = expense.veryfiDocumentId != null;

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
                      color: AppTheme.cardTotalBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Icon(_icon(cat), color: const Color(0xFF1C1C1C), size: 22),
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
