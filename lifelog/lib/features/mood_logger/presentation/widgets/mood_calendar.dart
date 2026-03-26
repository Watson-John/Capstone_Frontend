import 'package:flutter/material.dart';

import '../../domain/models/mood_log.dart';

class MoodCalendar extends StatelessWidget {
  const MoodCalendar({
    super.key,
    required this.viewMonth,
    required this.selectedDate,
    required this.moodLogs,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDayTap,
  });

  final DateTime viewMonth;
  final DateTime selectedDate;
  final List<MoodLog> moodLogs;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final void Function(DateTime date, List<MoodLog> logs) onDayTap;

  static const _kDayHeaders = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  static const _kMonthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Groups mood logs by day-of-month, returning the most recent emoji per day
  /// and the full list of logs for that day.
  Map<int, _DayData> _buildDayMap() {
    final map = <int, _DayData>{};
    for (final log in moodLogs) {
      final dt = DateTime.parse(log.dateTime);
      if (dt.year == viewMonth.year && dt.month == viewMonth.month) {
        final day = dt.day;
        map.putIfAbsent(day, () => _DayData([], null));
        map[day]!.logs.add(log);
        // Most recent log wins (logs are ordered dateTime DESC from DB)
        map[day]!.emoji ??= log.emoji;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final selectedNorm =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
    final daysInMonth =
        DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;
    final dayMap = _buildDayMap();
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -100) {
          onNextMonth();
        } else if (details.primaryVelocity! > 100) {
          onPrevMonth();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Column(
          children: [
            // ── Month navigation ──────────────────────────────────────
            Row(
              children: [
                _NavButton(icon: Icons.chevron_left, onTap: onPrevMonth),
                Expanded(
                  child: Text(
                    '${_kMonthNames[viewMonth.month - 1]} ${viewMonth.year}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                _NavButton(icon: Icons.chevron_right, onTap: onNextMonth),
              ],
            ),
            const SizedBox(height: 10),

            // ── Day headers ───────────────────────────────────────────
            Row(
              children: _kDayHeaders
                  .map((h) => Expanded(
                        child: Center(
                          child: Text(
                            h,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),

            // ── Day grid ──────────────────────────────────────────────
            ...List.generate(rows, (row) {
              return Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final day = cellIndex - startOffset + 1;

                  if (day < 1 || day > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 52));
                  }

                  final date =
                      DateTime(viewMonth.year, viewMonth.month, day);
                  final isToday = date == todayNorm;
                  final isSelected = date == selectedNorm;
                  final data = dayMap[day];
                  final hasLog = data != null;

                  final bgColor = isToday
                      ? cs.primary
                      : isSelected
                          ? cs.primaryContainer
                          : hasLog
                              ? cs.surfaceContainerHighest
                              : Colors.transparent;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (hasLog) {
                          onDayTap(date, data.logs);
                        }
                      },
                      child: SizedBox(
                        height: 52,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: bgColor,
                              ),
                              alignment: Alignment.center,
                              child: hasLog
                                  ? Text(
                                      data.emoji!,
                                      style: const TextStyle(fontSize: 20),
                                    )
                                  : Text(
                                      '$day',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isToday
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: isToday
                                            ? cs.onPrimary
                                            : cs.onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _DayData {
  final List<MoodLog> logs;
  String? emoji;
  _DayData(this.logs, this.emoji);
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: cs.onSurface),
      ),
    );
  }
}
