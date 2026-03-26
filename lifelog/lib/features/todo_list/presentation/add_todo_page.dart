import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/services/notification_service.dart';
import '../domain/models/todo_model.dart';
import '../../expense_tracker/domain/models/category_styles.dart';

class AddTodoPage extends StatefulWidget {
  final Todo? todoToEdit;
  const AddTodoPage({super.key, this.todoToEdit});

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(hours: 1));
  String _status = 'To Do';
  // New state
  bool _isAllDay = false;
  String? _labelColor; // stores a kCategoryStyles key, e.g. 'DINING'
  int? _reminderMinutes;
  bool _isRecurring = false;
  String? _recurrenceType;
  Set<String> _recurrenceDays = {};
  bool _hasRecurrenceEnd = false; // false = "Never"

  static const int _titleMaxLength = 50;

  // Keys from kCategoryStyles used as the color palette
  static const List<String> _kLabelKeys = [
    'GROCERY', 'BEAUTY_CARE', 'PHARMACY', 'CLOTHING', 'KIDS',
    'ELECTRONICS', 'HOME_DECOR', 'DINING', 'TRAVEL', 'FUEL_AUTO',
    'HOUSEHOLD', 'BOOKS_OFFICE', 'PET_SUPPLIES', 'FEES_TAX', 'OTHER',
  ];
  static const List<String> _weekDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  static const List<Map<String, dynamic>> _reminderOptions = [
    {'label': 'None', 'value': null},
    {'label': 'At time', 'value': 0},
    {'label': '5 min before', 'value': 5},
    {'label': '15 min before', 'value': 15},
    {'label': '30 min before', 'value': 30},
    {'label': '1 hour before', 'value': 60},
    {'label': '1 day before', 'value': 1440},
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.todoToEdit;
    if (t != null) {
      _titleController.text = t.task;
      _detailsController.text = t.details ?? '';
      _startDate = t.startDate;
      _dueDate = t.dueDate;
      _status = t.status;
      _isAllDay = t.isAllDay;
      _labelColor = t.category;
      _reminderMinutes = t.reminderMinutes;
      _isRecurring = t.isRecurring;
      _recurrenceType = t.recurrenceType;
      _recurrenceDays = t.recurrenceDays != null
          ? Set<String>.from(t.recurrenceDays!.split(','))
          : {};
      // A dueDate of year 2099 is the sentinel for "no end date"
      _hasRecurrenceEnd = t.isRecurring && t.dueDate.year != 2099;
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime initialDate = isStart ? _startDate : _dueDate;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;

      if (_isAllDay) {
        setState(() {
          if (isStart) {
            _startDate = DateTime(
                pickedDate.year, pickedDate.month, pickedDate.day, 0, 0);
            if (_dueDate.isBefore(_startDate)) {
              _dueDate = _startDate;
            }
          } else {
            _dueDate = DateTime(
                pickedDate.year, pickedDate.month, pickedDate.day, 23, 59);
          }
        });
        return;
      }

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        setState(() {
          final newDT = DateTime(pickedDate.year, pickedDate.month,
              pickedDate.day, pickedTime.hour, pickedTime.minute);
          if (isStart) {
            _startDate = newDT;
            if (_dueDate.isBefore(_startDate)) {
              _dueDate = _startDate.add(const Duration(hours: 1));
            }
          } else {
            _dueDate = newDT;
          }
        });
      }
    }
  }

  /// For recurring tasks: pick just a time (updates the time part of _startDate).
  Future<void> _selectRecurringTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(_startDate.year, _startDate.month,
            _startDate.day, picked.hour, picked.minute);
      });
    }
  }

  /// For recurring tasks: pick just a date (start or end).
  Future<void> _selectDateOnly(BuildContext context, bool isStart) async {
    final initial = isStart ? _startDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(picked.year, picked.month, picked.day,
              _startDate.hour, _startDate.minute);
        } else {
          _dueDate = DateTime(picked.year, picked.month, picked.day, 23, 59);
        }
      });
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) return;

    final recurrenceDaysStr =
        _isRecurring && _recurrenceType == 'weekly' && _recurrenceDays.isNotEmpty
            ? _recurrenceDays.join(',')
            : null;

    // For recurring tasks with no end, use year-2099 sentinel as dueDate.
    final effectiveDueDate = (_isRecurring && !_hasRecurrenceEnd)
        ? DateTime(2099, 12, 31, 23, 59)
        : _dueDate;

    final newTodo = Todo(
      id: widget.todoToEdit?.id,
      task: _titleController.text.trim(),
      details: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
      startDate: _startDate,
      dueDate: effectiveDueDate,
      status: _status,
      isAllDay: _isAllDay,
      isRecurring: _isRecurring,
      recurrenceType: _isRecurring ? _recurrenceType : null,
      recurrenceDays: recurrenceDaysStr,
      reminderMinutes: _reminderMinutes,
      category: _labelColor,
    );

    if (widget.todoToEdit == null) {
      await DatabaseHelper().insertTodo(newTodo);
      _scheduleBackendNotification(newTodo);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Task added!')));
      }
    } else {
      await DatabaseHelper().updateTodo(newTodo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changes saved successfully!')));
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  void _scheduleBackendNotification(Todo todo) {
    Future(() async {
      try {
        if (!await NotificationService.isEnabled()) return;
        final prefs = await SharedPreferences.getInstance();
        final deviceId = prefs.getString('device_id');
        final baseUrl = dotenv.env['BACKEND_URL'];
        if (deviceId == null || baseUrl == null) return;

        final notifyAt = todo.reminderMinutes != null
            ? todo.startDate
                .subtract(Duration(minutes: todo.reminderMinutes!))
                .toUtc()
            : todo.startDate.toUtc();

        final url = Uri.parse('$baseUrl/api/notifications/schedule/todo/');
        http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'notification': todo.task,
                'date_time': notifyAt.toIso8601String(),
                'device_id': deviceId,
              }),
            )
            .timeout(const Duration(seconds: 10))
            .then((res) {
          if (res.statusCode != 200 && res.statusCode != 201) {
            debugPrint('Backend notification failed: ${res.body}');
          }
        }).catchError((e) {
          debugPrint('Error scheduling notification: $e');
        });
      } catch (e) {
        debugPrint('Error preparing notification: $e');
      }
    });
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  String _formatTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String _formatDateTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(d)}  $h:$m $period';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  // ─── Reusable section label ──────────────────────────────────────────────
  Widget _sectionLabel(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label,
      {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurfaceVariant),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.todoToEdit != null;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To-Do List',
                style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700, color: cs.onSurface)),
            Text(isEditing ? 'Edit Task' : 'Add Task',
                style: textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? 'Edit Your Task' : 'Add Your Task',
                  style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 16),

                // ── All-Day Toggle ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('All Day',
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Switch(
                      value: _isAllDay,
                      onChanged: (v) => setState(() => _isAllDay = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Title ───────────────────────────────────────────────
                TextField(
                  controller: _titleController,
                  maxLength: _titleMaxLength,
                  maxLines: 1,
                  style: TextStyle(color: cs.onSurface, fontSize: 16),
                  decoration:
                      _inputDecoration(context, 'Title', hint: 'What needs to be done?'),
                ),
                const SizedBox(height: 12),

                // ── Details ─────────────────────────────────────────────
                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  style: TextStyle(color: cs.onSurface, fontSize: 15),
                  decoration: _inputDecoration(context, 'Details',
                      hint: 'Add more details (optional)'),
                ),
                const SizedBox(height: 16),

                // ── Dates (context-aware) ───────────────────────────────
                _sectionLabel(context, 'DATES'),
                if (!_isRecurring) ...[
                  // One-time task: Start + Due with full date+time
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDateTime(context, true),
                          child: _dateBox(context, 'Start',
                              _isAllDay ? _formatDate(_startDate) : _formatDateTime(_startDate)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDateTime(context, false),
                          child: _dateBox(context, 'Due',
                              _isAllDay ? _formatDate(_dueDate) : _formatDateTime(_dueDate)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Recurring task: Time + Starts + Ends
                  Row(
                    children: [
                      if (!_isAllDay) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectRecurringTime(context),
                            child: _dateBox(context, 'Time',
                                _formatTime(_startDate)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDateOnly(context, true),
                          child: _dateBox(context, 'Starts',
                              _formatDate(_startDate)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('End Date',
                          style: textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          Text('Never',
                              style: textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                          const SizedBox(width: 4),
                          Switch(
                            value: _hasRecurrenceEnd,
                            onChanged: (v) =>
                                setState(() => _hasRecurrenceEnd = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_hasRecurrenceEnd)
                    GestureDetector(
                      onTap: () => _selectDateOnly(context, false),
                      child: _dateBox(context, 'Ends on',
                          _formatDate(_dueDate)),
                    ),
                ],
                const SizedBox(height: 16),

                // ── Color Label ─────────────────────────────────────────
                _sectionLabel(context, 'COLOR LABEL'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // "None" option
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _labelColor = null),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.surfaceContainerHighest,
                              border: Border.all(
                                color: _labelColor == null
                                    ? cs.primary
                                    : cs.outlineVariant,
                                width: _labelColor == null ? 2.5 : 1,
                              ),
                            ),
                            child: _labelColor == null
                                ? Icon(Icons.close,
                                    size: 14,
                                    color: cs.onSurfaceVariant)
                                : null,
                          ),
                        ),
                      ),
                      ..._kLabelKeys.map((key) {
                        final style = styleForCategory(key);
                        final selected = _labelColor == key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _labelColor = key),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: style.background,
                                border: Border.all(
                                  color: selected
                                      ? style.foreground
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: style.foreground
                                              .withValues(alpha: 0.4),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Reminder ────────────────────────────────────────────
                _sectionLabel(context, 'REMINDER'),
                DropdownButtonFormField<int?>(
                  initialValue: _reminderMinutes,
                  decoration: _inputDecoration(context, 'Remind me'),
                  items: _reminderOptions.map((opt) {
                    return DropdownMenuItem<int?>(
                      value: opt['value'] as int?,
                      child: Text(opt['label'] as String),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _reminderMinutes = v),
                ),
                const SizedBox(height: 16),

                // ── Recurring ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionLabel(context, 'RECURRING'),
                    Switch(
                      value: _isRecurring,
                      onChanged: (v) => setState(() {
                        _isRecurring = v;
                        if (v) _recurrenceType ??= 'daily';
                      }),
                    ),
                  ],
                ),
                if (_isRecurring) ...[
                  Wrap(
                    spacing: 8,
                    children: ['daily', 'weekly', 'monthly'].map((type) {
                      final selected = _recurrenceType == type;
                      return ChoiceChip(
                        label: Text(
                            type[0].toUpperCase() + type.substring(1)),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _recurrenceType = type),
                        selectedColor: cs.primaryContainer,
                        side: BorderSide(
                            color: selected
                                ? cs.primary
                                : cs.outlineVariant),
                      );
                    }).toList(),
                  ),
                  if (_recurrenceType == 'weekly') ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: _weekDays.map((day) {
                        final on = _recurrenceDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: on,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _recurrenceDays.add(day);
                            } else {
                              _recurrenceDays.remove(day);
                            }
                          }),
                          selectedColor: cs.primaryContainer,
                          side: BorderSide(
                              color:
                                  on ? cs.primary : cs.outlineVariant),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),

                const SizedBox(height: 4),

                // ── Save ────────────────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _saveTask,
                    child: Text(isEditing ? 'Update Task' : 'Add Task',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateBox(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: textTheme.labelSmall?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurface, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
