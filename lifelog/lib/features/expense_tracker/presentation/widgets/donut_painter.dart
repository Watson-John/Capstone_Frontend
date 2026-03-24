import 'dart:math' as math;

import 'package:flutter/material.dart';

class DonutPainter extends CustomPainter {
  const DonutPainter({
    required this.spent,
    required this.total,
    required this.spentColor,
    required this.remainColor,
    required this.trackColor,
  });

  final double spent;
  final double total;
  final Color spentColor;
  final Color remainColor;
  final Color trackColor;

  static const _strokeWidth = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - _strokeWidth / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    if (total <= 0) {
      canvas.drawArc(
          rect, -math.pi / 2, 2 * math.pi, false, paint..color = trackColor);
      return;
    }

    final ratio = (spent / total).clamp(0.0, 1.0);
    final spentAngle = 2 * math.pi * ratio;
    final remainAngle = 2 * math.pi * (1 - ratio);

    // Track ring
    canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi, false, paint..color = trackColor);

    // Spent arc
    if (ratio > 0) {
      canvas.drawArc(
          rect, -math.pi / 2, spentAngle, false, paint..color = spentColor);
    }

    // Remaining arc
    if (ratio < 1) {
      canvas.drawArc(rect, -math.pi / 2 + spentAngle, remainAngle, false,
          paint..color = remainColor);
    }
  }

  @override
  bool shouldRepaint(DonutPainter old) =>
      old.spent != spent || old.total != total;
}
