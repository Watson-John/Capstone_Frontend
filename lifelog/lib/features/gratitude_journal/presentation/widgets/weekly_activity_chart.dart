import 'package:flutter/material.dart';

import '../../domain/models/gratitude_entry.dart';

class WeeklyActivityChart extends StatelessWidget {
  const WeeklyActivityChart({super.key, required this.entries});

  final List<GratitudeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build a set of date strings for entries this week
    final entryDays = <String>{};
    for (final e in entries) {
      final dt = DateTime.parse(e.dateTime);
      entryDays.add('${dt.year}-${dt.month}-${dt.day}');
    }

    // Week starts Monday (weekday 1). Find Monday of current week.
    final monday = today.subtract(Duration(days: today.weekday - 1));

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 100,
      child: CustomPaint(
        painter: _WeeklyBarPainter(
          monday: monday,
          today: today,
          entryDays: entryDays,
          dayLabels: dayLabels,
          filledColor: cs.primary,
          emptyColor: cs.outline,
          labelColor: cs.onSurfaceVariant,
          todayLabelColor: cs.primary,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WeeklyBarPainter extends CustomPainter {
  _WeeklyBarPainter({
    required this.monday,
    required this.today,
    required this.entryDays,
    required this.dayLabels,
    required this.filledColor,
    required this.emptyColor,
    required this.labelColor,
    required this.todayLabelColor,
  });

  final DateTime monday;
  final DateTime today;
  final Set<String> entryDays;
  final List<String> dayLabels;
  final Color filledColor;
  final Color emptyColor;
  final Color labelColor;
  final Color todayLabelColor;

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 7;
    const labelHeight = 18.0;
    const barPadding = 8.0;

    final availableWidth = size.width;
    final barWidth = (availableWidth - barPadding * (barCount - 1)) / barCount;
    final maxBarHeight = size.height - labelHeight - 8;

    for (int i = 0; i < barCount; i++) {
      final day = monday.add(Duration(days: i));
      final dayKey = '${day.year}-${day.month}-${day.day}';
      final hasEntry = entryDays.contains(dayKey);
      final isToday = day == today;
      final isFuture = day.isAfter(today);

      final x = i * (barWidth + barPadding);

      // Bar height: filled = full, empty = 40%, future = 25%
      final heightFraction = hasEntry ? 1.0 : (isFuture ? 0.25 : 0.4);
      final barHeight = maxBarHeight * heightFraction;
      final barTop = maxBarHeight - barHeight;

      final paint = Paint()
        ..color = hasEntry
            ? filledColor.withValues(alpha: isToday ? 1.0 : 0.75)
            : emptyColor.withValues(alpha: isFuture ? 0.15 : 0.3)
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, barTop, barWidth, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, paint);

      // Today dot indicator above bar
      if (isToday) {
        final dotPaint = Paint()
          ..color = filledColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(x + barWidth / 2, barTop - 6),
          3,
          dotPaint,
        );
      }

      // Day label below bar
      final labelPainter = TextPainter(
        text: TextSpan(
          text: dayLabels[i],
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? todayLabelColor : labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(
          x + barWidth / 2 - labelPainter.width / 2,
          size.height - labelHeight,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_WeeklyBarPainter old) =>
      old.entryDays != entryDays || old.today != today;
}
