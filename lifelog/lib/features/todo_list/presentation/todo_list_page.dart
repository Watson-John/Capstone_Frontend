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
  final ScrollController _dateScrollController = ScrollController();
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _loadTodos();

    // Scroll so the current date is the first visible item.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollController.hasClients) {
        const double itemWidth = 48.0;
        final targetScroll = (_selectedDate.day - 1) * itemWidth;
        _dateScrollController.jumpTo(
          targetScroll.clamp(
              0.0, _dateScrollController.position.maxScrollExtent),
        );
      }
    });
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
    _dateScrollController.dispose();
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

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked.month != _selectedDate.month) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, 1);
      });
      if (_dateScrollController.hasClients) {
        _dateScrollController.jumpTo(0);
      }
    }
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
      floatingActionButton: AppFab(onPressed: _navigateToAddTodo),
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
          GestureDetector(
            onTap: () => _selectMonth(context),
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
                  Icon(Icons.keyboard_arrow_down,
                      color: cs.onPrimary, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date selector row
          DateSelectorRow(
            selectedDate: _selectedDate,
            daysInMonth: _daysInMonth,
            controller: _dateScrollController,
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

class DateSelectorRow extends StatelessWidget {
  const DateSelectorRow({
    super.key,
    required this.selectedDate,
    required this.daysInMonth,
    required this.controller,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final int daysInMonth;
  final ScrollController controller;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.06, 0.88, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: List.generate(daysInMonth, (index) {
            final day = index + 1;
            final isSelected = day == selectedDate.day;
            return GestureDetector(
              onTap: () => onDateSelected(
                  DateTime(selectedDate.year, selectedDate.month, day)),
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? cs.primary : AppTheme.cardChildBg,
                  border: isSelected ? null : Border.all(color: cs.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.06),
                      blurRadius: isSelected ? 6 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? cs.onPrimary : cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }),
        ),
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
