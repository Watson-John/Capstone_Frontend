import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/app_page_header.dart';
import '../domain/models/todo_model.dart';
import 'widgets/calendar_dropdown.dart';
import 'widgets/date_selector_row.dart';
import 'widgets/empty_task_state.dart';
import 'widgets/task_timeline_card.dart';
import 'widgets/tasks_bottom_sheet.dart';
import 'widgets/todo_stats_card.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  DateTime _selectedDate = DateTime.now();
  List<Todo> _todos = [];
  bool _isCalendarExpanded = false;
  late DateTime _calendarViewMonth;

  @override
  void initState() {
    super.initState();
    _calendarViewMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final todos = await DatabaseHelper().getTodos();
    if (mounted) {
      setState(() {
        _todos = todos;
      });
    }
  }

  int get _daysInMonth {
    final nextMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _toggleCalendar() {
    setState(() {
      _isCalendarExpanded = !_isCalendarExpanded;
      if (_isCalendarExpanded) {
        _calendarViewMonth =
            DateTime(_selectedDate.year, _selectedDate.month);
      }
    });
  }

  void _prevCalendarMonth() => setState(() {
        _calendarViewMonth = DateTime(
            _calendarViewMonth.year, _calendarViewMonth.month - 1);
      });

  void _nextCalendarMonth() => setState(() {
        _calendarViewMonth = DateTime(
            _calendarViewMonth.year, _calendarViewMonth.month + 1);
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

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _triggerDemoNotification() async {
    if (_todos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks found. Add a task first.')),
      );
      return;
    }

    final mostRecent = _todos.reduce(
      (a, b) => (a.id ?? 0) > (b.id ?? 0) ? a : b,
    );

    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id');
    final baseUrl = dotenv.env['BACKEND_URL'];

    if (deviceId == null || baseUrl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device not registered. Restart the app.')),
      );
      return;
    }

    // Schedule date_time 10min+30s from now so notify_at = ~30s from now
    final dateTime = DateTime.now().toUtc().add(const Duration(minutes: 10, seconds: 5));

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/schedule/todo/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'notification': mostRecent.task,
          'date_time': dateTime.toIso8601String(),
          'device_id': deviceId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demo notification for "${mostRecent.task}" fires in ~5s')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _navigateToAddTodo() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.addTodo);
    if (result == true) {
      _loadTodos();
    }
  }

  List<Todo> get _todosForSelectedDate {
    final sel = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _todos.where((t) {
      final start =
          DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
      final end = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return !sel.isBefore(start) && !sel.isAfter(end);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const AppPageHeader(title: 'To-Do List'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _triggerDemoNotification,
                    icon: const Icon(Icons.notifications_active, size: 18),
                    label: const Text('Demo: Notify Latest Task'),
                  ),
                ),
                const SizedBox(height: 4),
                _buildScheduleCard(context, cs),
                const SizedBox(height: 16),
                TodoStatsCard(
                  todos: _todos,
                  onCategoryTap: (title, tasks) => showTasksBottomSheet(
                    context,
                    title: title,
                    tasks: tasks,
                    onReload: _loadTodos,
                  ),
                ),
                const SizedBox(height: 96),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: AppFab(heroTag: 'todo-fab', onPressed: _navigateToAddTodo),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildScheduleCard(BuildContext context, ColorScheme cs) {
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
          // Month selector
          Row(
            children: [
              GestureDetector(
                onTap: _toggleCalendar,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

          // Calendar dropdown
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            child: _isCalendarExpanded
                ? CalendarDropdown(
                    viewMonth: _calendarViewMonth,
                    selectedDate: _selectedDate,
                    todos: _todos,
                    onPrevMonth: _prevCalendarMonth,
                    onNextMonth: _nextCalendarMonth,
                    onDayTap: _onCalendarDayTap,
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Date selector row
          DateSelectorRow(
            key: ValueKey('${_selectedDate.year}-${_selectedDate.month}'),
            selectedDate: _selectedDate,
            daysInMonth: _daysInMonth,
            onDateSelected: _onDateSelected,
          ),
          const SizedBox(height: 20),

          // Task list for selected day
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
                      onReload: _loadTodos,
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
