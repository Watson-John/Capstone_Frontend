import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../domain/models/todo_model.dart';
import 'add_todo_page.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  DateTime _selectedDate = DateTime.now();
  final CalendarController _calendarController = CalendarController();
  final ScrollController _dateScrollController = ScrollController();
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _calendarController.displayDate = _selectedDate;
    _loadTodos();

    // Automatically scroll horizontal day list to selected day
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollController.hasClients) {
        // Approximate width of item + margin (36 + 8) = 44. Center roughly.
        final targetScroll = (_selectedDate.day - 1) * 44.0;
        final screenWidth = MediaQuery.of(context).size.width;
        final centeredScroll = (targetScroll - (screenWidth / 2) + 22)
            .clamp(0.0, _dateScrollController.position.maxScrollExtent);

        _dateScrollController.jumpTo(centeredScroll);
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
    _calendarController.dispose();
    _dateScrollController.dispose();
    super.dispose();
  }

  int get _daysInMonth {
    final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    return lastDay.day;
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER'
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
        _calendarController.displayDate = _selectedDate;
      });
      if (_dateScrollController.hasClients) {
        _dateScrollController.jumpTo(0);
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _calendarController.displayDate = date;
    });
  }

  Future<void> _navigateToAddTodo() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.addTodo);
    if (result == true) {
      _loadTodos(); // Refresh the list if a task was added
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EDCE), // Beige background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildMainCard(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildCardHeader(),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1.5, color: Color(0xFFDCDFD8)),
          const SizedBox(height: 24),
          _buildScheduleView(context),
          const SizedBox(height: 24),
          _buildStatsGrid(),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF5CCB44),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.check, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'TO DO LIST',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3B4863),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: _navigateToAddTodo,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B4863),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text(
            'Add Task',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Light blue-grey background
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        children: [
          const Text(
            'Today\'s Task',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3B4863),
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              GestureDetector(
                onTap: () => _selectMonth(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B4863),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getMonthYearString(_selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDateSelector(),
          const SizedBox(height: 24),
          SizedBox(
            height: 400, // Fixed height for calendar
            child: SfCalendar(
              controller: _calendarController,
              view: CalendarView.day,
              headerHeight: 0,
              viewHeaderHeight: 0,
              todayHighlightColor: const Color(0xFF3B4863),
              onTap: (CalendarTapDetails details) {
                if (details.appointments != null &&
                    details.appointments!.isNotEmpty) {
                  final Appointment appointment = details.appointments!.first;
                  final int todoId = appointment.id as int;
                  final Todo matchedTodo =
                      _todos.firstWhere((t) => t.id == todoId);
                  _showTasksBottomSheet(context, 'Task Details', [matchedTodo]);
                }
              },
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 0,
                endHour: 24,
                timeFormat: 'H:mm',
                timeIntervalHeight: 60,
                timeTextStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3B4863),
                ),
              ),
              dataSource: _getDataSource(),
              appointmentBuilder: (context, calendarAppointmentDetails) {
                final Appointment appointment =
                    calendarAppointmentDetails.appointments.first;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: appointment.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: appointment.color, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.subject,
                        style: TextStyle(
                          color: appointment.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Text(
                          '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}',
                          style: TextStyle(
                            color: appointment.color.withOpacity(0.8),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
              onViewChanged: (ViewChangedDetails details) {
                // Sync the date selector when calendar is swiped
                if (details.visibleDates.isNotEmpty) {
                  final newDate = details.visibleDates.first;
                  if (newDate.day != _selectedDate.day ||
                      newDate.month != _selectedDate.month ||
                      newDate.year != _selectedDate.year) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedDate = newDate;
                        });
                      }
                    });
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    int minute = time.minute;
    String period = hour >= 12 ? 'P.M.' : 'A.M.';
    hour = hour > 12 ? hour - 12 : hour;
    if (hour == 0) hour = 12;
    String minuteStr = minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $period';
  }

  Widget _buildDateSelector() {
    final daysCount = _daysInMonth;
    return SingleChildScrollView(
      controller: _dateScrollController,
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none, // Allow shadows to be visible while scrolling
      child: Row(
        mainAxisSize: MainAxisSize.min, // Hug content
        children: List.generate(daysCount, (index) {
          final day = index + 1;
          final isSelected = day == _selectedDate.day;
          return GestureDetector(
            onTap: () => _onDateSelected(
                DateTime(_selectedDate.year, _selectedDate.month, day)),
            child: Container(
              width: 36,
              height: 36,
              margin: EdgeInsets.only(
                right: 8,
                left: index == 0
                    ? 0
                    : 4, // Add slight left margin for better spacing
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF3B4863) : Colors.white,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF3B4863).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF3B4863),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final int total = _todos.length;
    final int todoCount = _todos.where((t) => t.status == 'To Do').length;
    final int inProgressCount =
        _todos.where((t) => t.status == 'In Progress').length;
    final int completedCount =
        _todos.where((t) => t.status == 'Completed').length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        _buildStatCard('Total Task', total.toString(), Colors.white,
            const Color(0xFF3B4863), _todos),
        _buildStatCard(
            'To Do',
            todoCount.toString(),
            const Color(0xFFDF9E9D),
            const Color(0xFF3B4863),
            _todos.where((t) => t.status == 'To Do').toList()),
        _buildStatCard(
            'In Progress',
            inProgressCount.toString(),
            const Color(0xFFEBECF1),
            const Color(0xFF3B4863),
            _todos.where((t) => t.status == 'In Progress').toList()),
        _buildStatCard(
            'Completed',
            completedCount.toString(),
            const Color(0xFFAED4A4),
            const Color(0xFF3B4863),
            _todos.where((t) => t.status == 'Completed').toList()),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, Color bgColor,
      Color textColor, List<Todo> filteredTasks) {
    return GestureDetector(
      onTap: () => _showTasksBottomSheet(context, title, filteredTasks),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: bgColor == Colors.white
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                color: textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTasksBottomSheet(
      BuildContext context, String title, List<Todo> tasks) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF3B4863),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const Divider(thickness: 1.5),
                  Expanded(
                    child: tasks.isEmpty
                        ? const Center(
                            child: Text("No tasks in this category."))
                        : ListView.builder(
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final todo = tasks[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                                color: const Color(0xFFF1F5F9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              todo.task,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF2B3A55),
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    color: Color(0xFF3B4863),
                                                    size: 20),
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
                                                      Navigator.pop(
                                                          sheetContext); // Close overlay after saving
                                                    }
                                                    _loadTodos(); // Refresh list
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red,
                                                    size: 20),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () async {
                                                  if (todo.id != null) {
                                                    await DatabaseHelper()
                                                        .deleteTodo(todo.id!);
                                                    if (sheetContext.mounted) {
                                                      Navigator.pop(
                                                          sheetContext);
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                'Task deleted successfully!')),
                                                      );
                                                    }
                                                    _loadTodos();
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule,
                                              size: 14,
                                              color: Color(0xFF3B4863)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${todo.startDate.month.toString().padLeft(2, '0')}/${todo.startDate.day.toString().padLeft(2, '0')}/${todo.startDate.year}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 4.0),
                                            child: Text('-',
                                                style: TextStyle(fontSize: 12)),
                                          ),
                                          Text(
                                            '${todo.dueDate.month.toString().padLeft(2, '0')}/${todo.dueDate.day.toString().padLeft(2, '0')}/${todo.dueDate.year}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Status:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Container(
                                            height: 36,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey.shade400),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: todo.status,
                                                icon: const Icon(
                                                    Icons.arrow_drop_down,
                                                    color: Color(0xFF3B4863)),
                                                style: const TextStyle(
                                                  color: Color(0xFF3B4863),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                items: <String>[
                                                  'To Do',
                                                  'In Progress',
                                                  'Completed'
                                                ].map<DropdownMenuItem<String>>(
                                                    (String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
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
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                'Changes saved successfully!')),
                                                      );
                                                    }

                                                    // Also update local list so modal shows new value
                                                    setModalState(() {
                                                      tasks[index] =
                                                          updatedTodo;
                                                    });

                                                    // Refresh the main page behind it
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

  _DataSource _getDataSource() {
    final List<Appointment> appointments = <Appointment>[];

    for (var todo in _todos) {
      Color taskColor;

      // Assign dynamic colors based on status, or fallback to an arbitrary color scheme
      if (todo.status == 'In Progress') {
        taskColor = const Color(0xFFE1B846); // Yellow for in progress
      } else if (todo.status == 'Completed') {
        taskColor = const Color(0xFF558B6E); // Green for completed
      } else {
        taskColor = const Color(0xFFDF9E9D); // Red/pink for Todo
      }

      appointments.add(Appointment(
        startTime: todo.startDate,
        endTime: todo.dueDate,
        subject: todo.task,
        color: taskColor,
        id: todo.id, // Store native ID for later click handling
      ));
    }

    return _DataSource(appointments);
  }
}

class _DataSource extends CalendarDataSource {
  _DataSource(List<Appointment> source) {
    appointments = source;
  }
}
