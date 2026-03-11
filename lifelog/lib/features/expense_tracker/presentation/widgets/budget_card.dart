import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/budget.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    required this.spent,
    required this.onEdit,
  });

  final Budget budget;
  final double spent;
  final VoidCallback onEdit;

  static Color _progressColor(double ratio) {
    if (ratio >= 1.0) return Colors.red.shade600;
    if (ratio >= 0.85) return Colors.orange.shade700;
    if (ratio >= 0.60) return Colors.amber.shade700;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();

    final ratio = budget.limitAmount > 0 ? spent / budget.limitAmount : 0.0;
    final remaining = budget.limitAmount - spent;
    final isOver = spent > budget.limitAmount;
    final color = _progressColor(ratio);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Budget · ${budget.periodLabel(now)}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  tooltip: 'Edit budget',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            // ── Arc gauge ────────────────────────────────────────
            SizedBox(
              height: 148,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GaugePainter(
                        progress: ratio.clamp(0.0, 1.0),
                        progressColor: color,
                        trackColor: colorScheme.surfaceContainerHighest,
                        strokeWidth: 18,
                      ),
                    ),
                  ),
                  // Text sits in the open bowl of the gauge
                  Positioned(
                    top: 44,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          '\$${spent.toStringAsFixed(2)} spent',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurface),
                        ),
                        Text(
                          'of \$${budget.limitAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Linear progress bar ──────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),

            // ── Footer labels ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$0',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                if (isOver)
                  Text(
                    '\$${(spent - budget.limitAmount).toStringAsFixed(2)} over budget',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    '\$${remaining.toStringAsFixed(2)} remaining',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                Text(
                  '\$${budget.limitAmount.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gauge painter ────────────────────────────────────────────────────────────
//
// Draws a 240° arc open at the bottom (like a car speedometer).
// 0° progress = empty arc; 1.0 = full arc.
//
// Flutter drawArc: 0 rad = 3 o'clock, sweeps clockwise.
//   150° from 3 o'clock = 8 o'clock position (bottom-left)
//   150° + 240° = 390° = 30° = 4 o'clock position (bottom-right)
//   Arc passes through 9, 12, and 3 o'clock — the top of the gauge.
class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress; // 0.0–1.0
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  static const double _startRad = 150 * math.pi / 180;
  static const double _sweepRad = 240 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    // Place center lower so the open mouth of the gauge faces downward
    // and the arc's top sits near the top of the widget.
    final cx = size.width / 2;
    // Radius chosen so bottom endpoints stay within the widget height.
    // Constraint: cy + radius * sin(30°) ≤ height  →  cy + r/2 ≤ h
    //             cy - radius ≥ 0                   →  cy ≥ r
    // We solve: r = (height - strokeWidth) / 1.6  and  cy = height - r/2 - strokeWidth/2
    final r = (size.height - strokeWidth) / 1.6;
    final cy = size.height - r * 0.5 - strokeWidth / 2;
    final radius = r - strokeWidth / 2;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Track (full arc)
    canvas.drawArc(
      rect,
      _startRad,
      _sweepRad,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress fill
    if (progress > 0) {
      canvas.drawArc(
        rect,
        _startRad,
        _sweepRad * progress,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}
