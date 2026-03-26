import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/mood_tag_styles.dart';

/// Full 360° donut chart showing mood distribution.
/// Each arc slice corresponds to a mood level using its semantic color.
class MoodDonutChart extends StatelessWidget {
  const MoodDonutChart({super.key, required this.moodCounts});

  /// mood label → count, e.g. {"great": 5, "okay": 2}
  final Map<String, int> moodCounts;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final present = kMoods.where((m) => (moodCounts[m.label] ?? 0) > 0).toList();
    final total = moodCounts.values.fold(0, (s, v) => s + v);

    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No data yet.',
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: CustomPaint(
            size: Size.infinite,
            painter: _DonutPainter(
              moods: present,
              counts: moodCounts,
              total: total,
              centerLabelColor: cs.onSurface,
              centerSubColor: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: present.map((m) {
            final count = moodCounts[m.label]!;
            final pct = (count / total * 100).round();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: m.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${m.emoji} ${m.label} $pct%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<MoodOption> moods;
  final Map<String, int> counts;
  final int total;
  final Color centerLabelColor;
  final Color centerSubColor;

  static const double _strokeWidth = 30.0;
  static const double _gapRad = 0.04; // gap between slices in radians

  _DonutPainter({
    required this.moods,
    required this.counts,
    required this.total,
    required this.centerLabelColor,
    required this.centerSubColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - _strokeWidth / 2 - 8;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Draw track (full circle, light grey).
    paint.color = Colors.black.withValues(alpha: 0.06);
    canvas.drawCircle(center, radius, paint);

    // Draw slices.
    double startAngle = -pi / 2; // start at top
    for (final mood in moods) {
      final count = counts[mood.label] ?? 0;
      if (count == 0) continue;
      final fraction = count / total;
      final sweep = fraction * 2 * pi - _gapRad;

      paint.color = mood.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + _gapRad / 2,
        sweep,
        false,
        paint,
      );
      startAngle += fraction * 2 * pi;
    }

    // Center: total count.
    _paintCenteredText(
      canvas,
      '$total',
      center.translate(0, -10),
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: centerLabelColor,
    );
    _paintCenteredText(
      canvas,
      total == 1 ? 'entry' : 'entries',
      center.translate(0, 14),
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: centerSubColor,
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
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.counts != counts || old.total != total;
}
