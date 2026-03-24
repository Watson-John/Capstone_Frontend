import 'package:flutter/material.dart';

class SummaryItem extends StatelessWidget {
  const SummaryItem({
    super.key,
    required this.label,
    required this.amount,
    required this.dotColor,
    this.onEditTap,
  });

  final String label;
  final double amount;
  final Color dotColor;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onEditTap != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onEditTap,
                child: Icon(Icons.edit_outlined,
                    size: 14, color: cs.outline),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
