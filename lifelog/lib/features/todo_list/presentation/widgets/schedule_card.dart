import 'package:flutter/material.dart';

import '../../domain/models/todo_model.dart';
import 'calendar_dropdown.dart';
import 'date_selector_row.dart';
import 'empty_task_state.dart';
import 'task_timeline_card.dart';
import 'tasks_bottom_sheet.dart';

/// A self-contained card that owns its own calendar/date state and renders
/// the schedule view (month selector, day strip, task list) for a given
/// [todos] list. Data loading stays in the parent page; this widget only
/// manages navigation within the calendar.
class ScheduleCard extends StatefulWidget {
  const ScheduleCard({
    super.key,
    required this.todos,
    required this.swipeLtrAction,
    required this.swipeRtlAction,
    required this.onSwipeAction,
    required this.onReload,
  });

  final List<Todo> todos;
  final String swipeLtrAction;
  final String swipeRtlAction;
  final Future<bool> Function(Todo todo, String action) onSwipeAction;
  final VoidCallback onReload;

  @override
  State<ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<ScheduleCard> {
  DateTime _selectedDate = DateTime.now();
  bool _isCalendarExpanded = false;
  late DateTime _calendarViewMonth;

  @override
  void initState() {
    super.initState();
    _calendarViewMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int get _daysInMonth {
    final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  List<Todo> get _todosForSelectedDate =>
      widget.todos.where((t) => t.appearsOnDate(_selectedDate)).toList();

  // ── Callbacks ──────────────────────────────────────────────────────────────

  void _toggleCalendar() {
    setState(() {
      _isCalendarExpanded = !_isCalendarExpanded;
      if (_isCalendarExpanded) {
        _calendarViewMonth = DateTime(_selectedDate.year, _selectedDate.month);
      }
    });
  }

  void _prevCalendarMonth() => setState(() {
        _calendarViewMonth =
            DateTime(_calendarViewMonth.year, _calendarViewMonth.month - 1);
      });

  void _nextCalendarMonth() => setState(() {
        _calendarViewMonth =
            DateTime(_calendarViewMonth.year, _calendarViewMonth.month + 1);
      });

  void _onCalendarDayTap(DateTime date) {
    setState(() {
      _selectedDate = date;
      _calendarViewMonth = DateTime(date.year, date.month);
      _isCalendarExpanded = false;
    });
  }

  void _jumpToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDate = today;
      _calendarViewMonth = DateTime(today.year, today.month);
      _isCalendarExpanded = false;
    });
  }

  void _onDateSelected(DateTime date) => setState(() => _selectedDate = date);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tasks = _todosForSelectedDate;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Month selector ───────────────────────────────────────────
          Row(
            children: [
              GestureDetector(
                onTap: _toggleCalendar,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getMonthYearString(_selectedDate),
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: _isCalendarExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        child: Icon(Icons.keyboard_arrow_down,
                            color: cs.onPrimary, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _jumpToToday,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Calendar dropdown ────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            child: _isCalendarExpanded
                ? CalendarDropdown(
                    viewMonth: _calendarViewMonth,
                    selectedDate: _selectedDate,
                    todos: widget.todos,
                    onPrevMonth: _prevCalendarMonth,
                    onNextMonth: _nextCalendarMonth,
                    onDayTap: _onCalendarDayTap,
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // ── Date selector row ────────────────────────────────────────
          DateSelectorRow(
            key: ValueKey('${_selectedDate.year}-${_selectedDate.month}'),
            selectedDate: _selectedDate,
            daysInMonth: _daysInMonth,
            onDateSelected: _onDateSelected,
          ),

          const SizedBox(height: 20),

          // ── Task list ────────────────────────────────────────────────
          Text(
            "Today's Tasks",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            const EmptyTaskState()
          else
            ...tasks.map((todo) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TaskTimelineCard(
                    todo: todo,
                    onTap: () => showTasksBottomSheet(
                      context,
                      title: 'Task Details',
                      tasks: [todo],
                      onReload: widget.onReload,
                    ),
                    swipeLtrAction: widget.swipeLtrAction,
                    swipeRtlAction: widget.swipeRtlAction,
                    onSwipeLtr: (t) =>
                        widget.onSwipeAction(t, widget.swipeLtrAction),
                    onSwipeRtl: (t) =>
                        widget.onSwipeAction(t, widget.swipeRtlAction),
                  ),
                )),
        ],
      ),
    );
  }
}
