import 'package:flutter/material.dart';

/// A data point on the mood trend timeline.
class TrendPoint {
  final String label; // x-axis label (e.g. "Mon", "W1", "Jan")
  final double value; // average mood value 1–5 (0 = no data)
  final int count; // number of logs in this bucket
  const TrendPoint(this.label, this.value, this.count);
}

/// A line + dot chart showing mood trend over time.
/// All rendering is done in a single CustomPainter so Y-axis labels,
/// grid lines, and data points are always perfectly aligned.
class MoodTrendChart extends StatelessWidget {
  const MoodTrendChart({super.key, required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty || points.every((p) => p.count == 0)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No data for this period.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 200,
      child: CustomPaint(
        size: Size.infinite,
        painter: _TrendPainter(
          points: points,
          lineColor: cs.primary,
          dotColor: cs.primary,
          gridColor: cs.outlineVariant.withValues(alpha: 0.25),
          labelColor: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Custom Painter ──────────────────────────────────────────────────────────

class _TrendPainter extends CustomPainter {
  final List<TrendPoint> points;
  final Color lineColor;
  final Color dotColor;
  final Color gridColor;
  final Color labelColor;

  static const _yEmojis = ['😫', '☹️', '😐', '🙂', '😄']; // index 0 = awful (bottom)
  static const double _yAxisWidth = 32.0;
  static const double _xAxisHeight = 22.0;
  static const double _vertPad = 12.0; // top/bottom padding inside chart area

  _TrendPainter({
    required this.points,
    required this.lineColor,
    required this.dotColor,
    required this.gridColor,
    required this.labelColor,
  });

  // Convert mood value (1–5) to canvas Y coordinate.
  double _moodY(double v, double chartTop, double chartHeight) {
    return chartTop + _vertPad + (5 - v) / 4 * (chartHeight - 2 * _vertPad);
  }

  // Convert point index to canvas X coordinate (within chart area).
  double _pointX(int i, double chartLeft, double chartWidth) {
    if (points.length == 1) return chartLeft + chartWidth / 2;
    return chartLeft + (i / (points.length - 1)) * chartWidth;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Layout regions
    final double chartLeft = _yAxisWidth;
    final double chartTop = 0.0;
    final double chartRight = size.width;
    final double chartBottom = size.height - _xAxisHeight;
    final double chartWidth = chartRight - chartLeft;
    final double chartHeight = chartBottom - chartTop;

    // ── Grid lines ────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int level = 1; level <= 5; level++) {
      final y = _moodY(level.toDouble(), chartTop, chartHeight);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
    }

    // ── Y-axis emoji labels ───────────────────────────────────────────────
    for (int i = 0; i < 5; i++) {
      final moodVal = (i + 1).toDouble();
      final y = _moodY(moodVal, chartTop, chartHeight);
      _paintText(
        canvas,
        _yEmojis[i],
        Offset(0, y),
        fontSize: 14,
        color: Colors.black,
        alignCenter: true,
        maxWidth: _yAxisWidth,
      );
    }

    // ── Data line + dots ──────────────────────────────────────────────────
    // Only include points that have actual data.
    final dataCoords = <({int idx, Offset pos})>[];
    for (int i = 0; i < points.length; i++) {
      if (points[i].count > 0) {
        final x = _pointX(i, chartLeft, chartWidth);
        final y = _moodY(points[i].value, chartTop, chartHeight)
            .clamp(chartTop + _vertPad, chartBottom - _vertPad);
        dataCoords.add((idx: i, pos: Offset(x, y)));
      }
    }

    if (dataCoords.length > 1) {
      final linePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.55)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path()
        ..moveTo(dataCoords.first.pos.dx, dataCoords.first.pos.dy);
      for (int i = 1; i < dataCoords.length; i++) {
        path.lineTo(dataCoords[i].pos.dx, dataCoords[i].pos.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Dots on top of line.
    final dotFill = Paint()..color = dotColor;
    final dotBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final d in dataCoords) {
      canvas.drawCircle(d.pos, 5, dotFill);
      canvas.drawCircle(d.pos, 5, dotBorder);
    }

    // ── X-axis labels ─────────────────────────────────────────────────────
    for (int i = 0; i < points.length; i++) {
      final x = _pointX(i, chartLeft, chartWidth);
      _paintText(
        canvas,
        points[i].label,
        Offset(x, chartBottom + 4),
        fontSize: 10,
        color: labelColor,
        alignCenter: true,
        maxWidth: 36,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset position, {
    required double fontSize,
    required Color color,
    bool alignCenter = false,
    double maxWidth = 200,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final dx = alignCenter ? position.dx - tp.width / 2 : position.dx;
    final dy = position.dy - tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.points != points || old.lineColor != lineColor;
}
