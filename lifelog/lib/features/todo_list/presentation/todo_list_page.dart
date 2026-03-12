import 'package:flutter/material.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/app_page_header.dart';
import '../domain/models/todo_model.dart';
import 'add_todo_page.dart';

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

  @override
  void dispose() {
    super.dispose();
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

  Future<void> _navigateToAddTodo() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.addTodo);
    if (result == true) {
      _loadTodos();
    }
  }

  /// Tasks whose date range overlaps the selected date.
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
                const SizedBox(height: 16),
                _buildScheduleCard(context),
                const SizedBox(height: 16),
                _buildStatsCard(context),
                const SizedBox(height: 96),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AppFab(heroTag: 'todo-fab', onPressed: _navigateToAddTodo),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── Schedule card ──────────────────────────────────────────────────────────

  Widget _buildScheduleCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
              // Today shortcut
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
                ? _CalendarDropdown(
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
          _buildTaskList(context),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context) {
    final tasks = _todosForSelectedDate;
    if (tasks.isEmpty) {
      return _EmptyTaskState();
    }
    return Column(
      children: tasks
          .map((todo) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TaskTimelineCard(
                  todo: todo,
                  onTap: () =>
                      _showTasksBottomSheet(context, 'Task Details', [todo]),
                ),
              ))
          .toList(),
    );
  }

  // ── Stats card ─────────────────────────────────────────────────────────────

  Widget _buildStatsCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final int total = _todos.length;
    final int todoCount = _todos.where((t) => t.status == 'To Do').length;
    final int inProgressCount =
        _todos.where((t) => t.status == 'In Progress').length;
    final int completedCount =
        _todos.where((t) => t.status == 'Completed').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _buildStatCard(context, 'Total', total.toString(),
              AppTheme.cardTotalBg, cs.onSurface, _todos),
          _buildStatCard(context, 'To Do', todoCount.toString(),
              AppTheme.cardToDoBg, cs.onSurface,
              _todos.where((t) => t.status == 'To Do').toList()),
          _buildStatCard(context, 'In Progress', inProgressCount.toString(),
              AppTheme.cardInProgressBg, cs.onSurface,
              _todos.where((t) => t.status == 'In Progress').toList()),
          _buildStatCard(context, 'Completed', completedCount.toString(),
              AppTheme.cardCompletedBg, cs.onSurface,
              _todos.where((t) => t.status == 'Completed').toList()),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String count,
    Color bgColor,
    Color textColor,
    List<Todo> filteredTasks,
  ) {
    return GestureDetector(
      onTap: () => _showTasksBottomSheet(context, title, filteredTasks),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              count,
              style: TextStyle(
                fontSize: 26,
                color: textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet ───────────────────────────────────────────────────────────

  void _showTasksBottomSheet(
      BuildContext context, String title, List<Todo> tasks) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: tasks.isEmpty
                        ? const Center(
                            child: Text('No tasks in this category.'))
                        : ListView.builder(
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final todo = tasks[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              todo.task,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit,
                                                color: cs.onSurfaceVariant, size: 20),
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                            onPressed: () async {
                                              final updated =
                                                  await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AddTodoPage(
                                                          todoToEdit: todo),
                                                ),
                                              );
                                              if (updated == true) {
                                                if (sheetContext.mounted) {
                                                  Navigator.pop(sheetContext);
                                                }
                                                _loadTodos();
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: cs.error, size: 20),
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                            onPressed: () async {
                                              if (todo.id != null) {
                                                await DatabaseHelper()
                                                    .deleteTodo(todo.id!);
                                                if (sheetContext.mounted) {
                                                  Navigator.pop(sheetContext);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(const SnackBar(
                                                          content: Text(
                                                              'Task deleted successfully!')));
                                                }
                                                _loadTodos();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.schedule,
                                              size: 14,
                                              color: cs.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_fmtDate(todo.startDate)} → ${_fmtDate(todo.dueDate)}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: cs.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Status:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: cs.onSurface)),
                                          Container(
                                            height: 36,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: cs.surface,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: cs.outline),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: todo.status,
                                                icon: Icon(
                                                    Icons.arrow_drop_down,
                                                    color: cs.primary),
                                                style: TextStyle(
                                                  color: cs.onSurface,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                items: const [
                                                  'To Do',
                                                  'In Progress',
                                                  'Completed'
                                                ]
                                                    .map((v) =>
                                                        DropdownMenuItem(
                                                            value: v,
                                                            child: Text(v)))
                                                    .toList(),
                                                onChanged:
                                                    (String? newValue) async {
                                                  if (newValue != null &&
                                                      newValue != todo.status) {
                                                    final updatedTodo =
                                                        todo.copyWith(
                                                            status: newValue);
                                                    await DatabaseHelper()
                                                        .updateTodo(
                                                            updatedTodo);
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(const SnackBar(
                                                              content: Text(
                                                                  'Changes saved successfully!')));
                                                    }
                                                    setModalState(() {
                                                      tasks[index] = updatedTodo;
                                                    });
                                                    _loadTodos();
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
}

// ── DateSelectorRow ────────────────────────────────────────────────────────────

class DateSelectorRow extends StatefulWidget {
  const DateSelectorRow({
    super.key,
    required this.selectedDate,
    required this.daysInMonth,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final int daysInMonth;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<DateSelectorRow> createState() => _DateSelectorRowState();
}

class _DateSelectorRowState extends State<DateSelectorRow> {
  late final CarouselController _controller;

  static const _kWeekLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  void initState() {
    super.initState();
    _controller = CarouselController(initialItem: widget.selectedDate.day - 1);
  }

  @override
  void didUpdateWidget(DateSelectorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate.day != widget.selectedDate.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.animateTo(
            (widget.selectedDate.day - 1) * 64.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _weekLabel(int day) {
    final dt = DateTime(
        widget.selectedDate.year, widget.selectedDate.month, day);
    return _kWeekLabels[dt.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 74,
      child: CarouselView(
        controller: _controller,
        itemExtent: 64,
        shrinkExtent: 44,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onTap: (index) => widget.onDateSelected(DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          index + 1,
        )),
        children: List.generate(widget.daysInMonth, (index) {
          final day = index + 1;
          final isSelected = day == widget.selectedDate.day;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected ? cs.primary : AppTheme.cardChildBg,
              border: isSelected
                  ? null
                  : Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.30)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekLabel(day),
                  style: TextStyle(
                    color: isSelected
                        ? cs.onPrimary.withValues(alpha: 0.75)
                        : cs.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? cs.onPrimary : cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── TaskTimelineCard ───────────────────────────────────────────────────────────

class TaskTimelineCard extends StatelessWidget {
  const TaskTimelineCard({
    super.key,
    required this.todo,
    required this.onTap,
  });

  final Todo todo;
  final VoidCallback onTap;

  Color _statusBg(ColorScheme cs) {
    switch (todo.status) {
      case 'Completed':
        return AppTheme.cardCompletedBg;
      case 'In Progress':
        return AppTheme.cardInProgressBg;
      default: // To Do
        return AppTheme.cardToDoBg;
    }
  }

  Color _statusFg(ColorScheme cs) {
    return const Color(0xFF1C1C1C); // Always near-black — no colored text
  }

  Color _statusStripe(ColorScheme cs) {
    switch (todo.status) {
      case 'Completed':
        return AppTheme.accentGreen;         // dark sage green
      case 'In Progress':
        return const Color(0xFF8A4F00);      // brand brown (kept per spec)
      default: // To Do
        return const Color(0xFFB07D00);      // darker amber
    }
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardChildBg,        // Level 2: sits on top of white Level 1 card
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            // Status stripe
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _statusStripe(cs),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Task details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.task,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_fmtTime(todo.startDate)} – ${_fmtTime(todo.dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Status chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusBg(cs),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                todo.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _statusFg(cs),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyTaskState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.task_alt_outlined, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 10),
          Text(
            'No tasks for this day',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add one',
            style: TextStyle(color: cs.outline, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── CalendarDropdown ───────────────────────────────────────────────────────────

class _CalendarDropdown extends StatelessWidget {
  const _CalendarDropdown({
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

  /// Returns a map of day-of-month → set of statuses for tasks that overlap
  /// any day in [viewMonth].
  Map<int, Set<String>> _taskDays(int daysInMonth) {
    final map = <int, Set<String>>{};
    for (final todo in todos) {
      final start = DateTime(
          todo.startDate.year, todo.startDate.month, todo.startDate.day);
      final end = DateTime(
          todo.dueDate.year, todo.dueDate.month, todo.dueDate.day);
      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(viewMonth.year, viewMonth.month, d);
        if (!date.isBefore(start) && !date.isAfter(end)) {
          map.putIfAbsent(d, () => <String>{}).add(todo.status);
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
    // Sunday-first offset: Mon=1..Sun=7 → Sun=0, Mon=1 … Sat=6
    final startOffset = firstDay.weekday % 7;
    final taskDays = _taskDays(daysInMonth);
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        children: [
          // ── Nav header ──────────────────────────────────────────────────
          Row(
            children: [
              _NavButton(
                icon: Icons.chevron_left,
                onTap: onPrevMonth,
              ),
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
              _NavButton(
                icon: Icons.chevron_right,
                onTap: onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Day-of-week headers ─────────────────────────────────────────
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

          // ── Day grid ────────────────────────────────────────────────────
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
                final statuses = taskDays[day];

                // Color logic (today takes precedence)
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
                          // Task dots
                          if (statuses != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: _buildDots(statuses),
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

  List<Widget> _buildDots(Set<String> statuses) {
    final colors = <Color>[];
    if (statuses.contains('To Do')) colors.add(AppTheme.accentAmber);
    if (statuses.contains('In Progress')) colors.add(const Color(0xFF1F4A7A));
    if (statuses.contains('Completed')) colors.add(AppTheme.accentGreen);
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
