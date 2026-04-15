import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../expense_tracker/domain/models/category_styles.dart';
import '../../domain/models/todo_model.dart';

class CalendarDropdown extends StatelessWidget {
  const CalendarDropdown({
    super.key,
    required this.viewMonth,
    required this.selectedDate,
    required this.todos,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDayTap,
  });

  final DateTime viewMonth;
  final DateTime selectedDate;
  final List<Todo> todos;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDayTap;

  static const _kDayHeaders = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  static const _kMonthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static Color _dotColorFor(Todo todo) {
    if (todo.category != null) {
      return styleForCategory(todo.category!).foreground;
    }
    switch (todo.status) {
      case 'Completed':
        return AppTheme.accentGreen;
      case 'In Progress':
        return const Color(0xFF8A4F00);
      default:
        return AppTheme.accentAmber;
    }
  }

  Map<int, Set<Color>> _taskDays(int daysInMonth) {
    final map = <int, Set<Color>>{};
    for (final todo in todos) {
      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(viewMonth.year, viewMonth.month, d);
        if (todo.appearsOnDate(date)) {
          map.putIfAbsent(d, () => <Color>{}).add(_dotColorFor(todo));
        }
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayNorm =
        DateTime(today.year, today.month, today.day);
    final selectedNorm = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day);

    final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
    final daysInMonth =
        DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;
    final taskDays = _taskDays(daysInMonth);
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        children: [
          Row(
            children: [
              _NavButton(icon: Icons.chevron_left, onTap: onPrevMonth),
              Expanded(
                child: Text(
                  '${_kMonthNames[viewMonth.month - 1]} ${viewMonth.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              _NavButton(icon: Icons.chevron_right, onTap: onNextMonth),
            ],
          ),
          const SizedBox(height: 8),

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
          const SizedBox(height: 4),

          ...List.generate(rows, (row) {
            return Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final day = cellIndex - startOffset + 1;

                if (day < 1 || day > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 46));
                }

                final date =
                    DateTime(viewMonth.year, viewMonth.month, day);
                final isToday = date == todayNorm;
                final isSelected = date == selectedNorm;
                final dotColors = taskDays[day];

                final bgColor = isToday
                    ? cs.primary
                    : isSelected
                        ? cs.primaryContainer
                        : Colors.transparent;
                final textColor = isToday
                    ? cs.onPrimary
                    : isSelected
                        ? cs.primary
                        : cs.onSurface;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDayTap(date),
                    child: SizedBox(
                      height: 46,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: bgColor,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isToday || isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (dotColors != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: _buildDots(dotColors),
                            )
                          else
                            const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
          const SizedBox(height: 4),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
        ],
      ),
    );
  }

  List<Widget> _buildDots(Set<Color> colors) {
    return colors
        .take(3)
        .map((c) => Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(shape: BoxShape.circle, color: c),
            ))
        .toList();
  }
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
