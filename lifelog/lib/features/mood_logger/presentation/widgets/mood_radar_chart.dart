import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/mood_tag_styles.dart';

/// Radar / spider chart showing tag frequency.
/// Each axis = one tag, polygon area scales with count.
class MoodRadarChart extends StatelessWidget {
  const MoodRadarChart({super.key, required this.tagCounts});

  /// tag label → count, e.g. {"calm": 4, "anxious": 2}
  final Map<String, int> tagCounts;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nonZero = tagCounts.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (nonZero.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No tags logged yet.',
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
        ),
      );
    }

    // Cap at 8 axes for legibility.
    final tags = nonZero.take(8).toList();

    return SizedBox(
      height: 220,
      child: CustomPaint(
        size: Size.infinite,
        painter: _RadarPainter(
          tags: tags,
          primaryColor: cs.primary,
          gridColor: cs.outlineVariant.withValues(alpha: 0.3),
          axisColor: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<MapEntry<String, int>> tags;
  final Color primaryColor;
  final Color gridColor;
  final Color axisColor;

  _RadarPainter({
    required this.tags,
    required this.primaryColor,
    required this.gridColor,
    required this.axisColor,
  });

  static const int _gridRings = 4;
  static const double _labelPad = 20.0; // space reserved around chart for labels

  @override
  void paint(Canvas canvas, Size size) {
    final n = tags.length;
    if (n == 0) return;

    final maxVal = tags.map((e) => e.value).reduce(max).toDouble();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - _labelPad;

    // Angle for each axis, starting straight up (-π/2).
    double axisAngle(int i) => -pi / 2 + i * (2 * pi / n);

    Offset axisPoint(int i, double fraction) {
      final a = axisAngle(i);
      return center + Offset(cos(a), sin(a)) * (radius * fraction);
    }

    // ── Background rings ────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= _gridRings; ring++) {
      final frac = ring / _gridRings;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final pt = axisPoint(i, frac);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // ── Axis lines ──────────────────────────────────────────────────────
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    for (int i = 0; i < n; i++) {
      final outer = axisPoint(i, 1.0);
      canvas.drawLine(center, outer, axisPaint);
    }

    // ── Data polygon ────────────────────────────────────────────────────
    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final frac = tags[i].value / maxVal;
      final pt = axisPoint(i, frac);
      i == 0 ? dataPath.moveTo(pt.dx, pt.dy) : dataPath.lineTo(pt.dx, pt.dy);
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Vertex dots ─────────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final frac = tags[i].value / maxVal;
      final pt = axisPoint(i, frac);
      canvas.drawCircle(pt, 4, Paint()..color = primaryColor);
      canvas.drawCircle(
          pt,
          4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    // ── Axis labels ─────────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final a = axisAngle(i);
      final labelRadius = radius + _labelPad - 4;
      final labelCenter =
          center + Offset(cos(a), sin(a)) * labelRadius;
      final tag = tags[i].key;
      final style = kTagStyles[tag];
      final labelColor =
          style?.foreground ?? const Color(0xFF444444);

      final tp = TextPainter(
        text: TextSpan(
          text: tag,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 60);

      tp.paint(
          canvas,
          Offset(
            labelCenter.dx - tp.width / 2,
            labelCenter.dy - tp.height / 2,
          ));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.tags != tags;
}
