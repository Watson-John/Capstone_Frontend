import 'package:flutter/material.dart';
import 'dart:math';

class HalfDonutChart extends StatelessWidget {
  final Map<String, int> moodCounts;

  const HalfDonutChart({super.key, required this.moodCounts});

  @override
  Widget build(BuildContext context) {
    if (moodCounts.isEmpty) return const SizedBox();

    final total = moodCounts.values.fold(0, (sum, count) => sum + count);

    // Sort keys or generate stable colors
    final keys = moodCounts.keys.toList();

    final List<Color> palette = [
      const Color(0xFF8A7CF3), // Purple
      const Color(0xFFFF8E8B), // Coral
      const Color(0xFF4ACBEA), // Light Blue
      const Color(0xFFF1C40F), // Yellow
      const Color(0xFF2ECC71), // Green
      const Color(0xFFE67E22), // Orange
      const Color(0xFFe84393), // Pink
    ];

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: CustomPaint(
            size: const Size(300, 150),
            painter: _HalfDonutPainter(
              moodCounts: moodCounts,
              total: total,
              keys: keys,
              palette: palette,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(keys.length, (index) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: palette[index % palette.length],
                ),
                const SizedBox(width: 8),
                Text(
                  keys[index],
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _HalfDonutPainter extends CustomPainter {
  final Map<String, int> moodCounts;
  final int total;
  final List<String> keys;
  final List<Color> palette;

  _HalfDonutPainter({
    required this.moodCounts,
    required this.total,
    required this.keys,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    const strokeWidth = 50.0; // Thickness of the donut

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    double startAngle = pi; // Start from the left (180 degrees)

    for (int i = 0; i < keys.length; i++) {
      final sweepAngle =
          (moodCounts[keys[i]]! / total) * pi; // Percentage of 180 degrees

      paint.color = palette[i % palette.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
