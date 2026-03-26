import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/mood_tag_styles.dart';

/// Segmented 180° arc gauge showing energy level distribution.
/// Three proportional segments: low / medium / high.
class MoodEnergyGauge extends StatelessWidget {
  const MoodEnergyGauge({super.key, required this.energyCounts});

  /// energy label → count, e.g. {"low": 2, "medium": 5, "high": 3}
  final Map<String, int> energyCounts;

  static const _order = ['low', 'medium', 'high'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = energyCounts.values.fold(0, (s, v) => s + v);

    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No energy data yet.',
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
        ),
      );
    }

    // Dominant energy level.
    final dominant = _order.reduce((a, b) =>
        (energyCounts[a] ?? 0) >= (energyCounts[b] ?? 0) ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 130,
          child: CustomPaint(
            size: Size.infinite,
            painter: _GaugePainter(
              counts: energyCounts,
              total: total,
              dominant: dominant,
              labelColor: cs.onSurface,
              subLabelColor: cs.onSurfaceVariant,
              trackColor: Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ),
        // Legend row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _order.map((level) {
            final count = energyCounts[level] ?? 0;
            if (count == 0) return const SizedBox.shrink();
            final pct = (count / total * 100).round();
            final color = kEnergyColors[level]!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$level $pct%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final Map<String, int> counts;
  final int total;
  final String dominant;
  final Color labelColor;
  final Color subLabelColor;
  final Color trackColor;

  static const _order = ['low', 'medium', 'high'];
  static const double _strokeWidth = 28.0;

  _GaugePainter({
    required this.counts,
    required this.total,
    required this.dominant,
    required this.labelColor,
    required this.subLabelColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Gauge center sits at the bottom-center of the canvas.
    final center = Offset(size.width / 2, size.height - 16);
    final radius = min(size.width / 2, size.height) - _strokeWidth / 2 - 8;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Track — full 180° arc (π radians), starting from left (π) going clockwise.
    paint.color = trackColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      paint,
    );

    // Filled segments.
    double startAngle = pi;
    const gapRad = 0.03;
    for (final level in _order) {
      final count = counts[level] ?? 0;
      if (count == 0) continue;
      final fraction = count / total;
      final sweep = fraction * pi - gapRad;

      paint.color = kEnergyColors[level]!;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gapRad / 2,
        sweep.clamp(0.01, pi),
        false,
        paint,
      );
      startAngle += fraction * pi;
    }

    // Dominant label centered above the arc center.
    _paintCenteredText(
      canvas,
      dominant,
      center.translate(0, -radius * 0.35),
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: labelColor,
    );
    _paintCenteredText(
      canvas,
      'dominant energy',
      center.translate(0, -radius * 0.35 + 22),
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: subLabelColor,
    );
  }

  void _paintCenteredText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2, -tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.counts != counts || old.total != total;
}
