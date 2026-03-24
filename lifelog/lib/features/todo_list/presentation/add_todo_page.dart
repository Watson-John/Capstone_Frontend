import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/dashed_border_painter.dart';
import '../domain/models/todo_model.dart';

class AddTodoPage extends StatefulWidget {
  final Todo? todoToEdit;
  const AddTodoPage({super.key, this.todoToEdit});

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  final TextEditingController _taskController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(hours: 1));
  String _status = 'To Do';
  String? _imagePath;
  List<Todo> _history = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.todoToEdit != null) {
      _taskController.text = widget.todoToEdit!.task;
      _startDate = widget.todoToEdit!.startDate;
      _dueDate = widget.todoToEdit!.dueDate;
      _status = widget.todoToEdit!.status;
      _imagePath = widget.todoToEdit!.imagePath;
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final todos = await DatabaseHelper().getTodos();
    if (mounted) {
      setState(() {
        _history = todos.reversed.toList(); // Newest first
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime initialDate = isStart ? _startDate : _dueDate;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF3B4863)),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3B4863)),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        setState(() {
          final newDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          if (isStart) {
            _startDate = newDateTime;
            if (_dueDate.isBefore(_startDate)) {
              _dueDate = _startDate.add(const Duration(hours: 1));
            }
          } else {
            _dueDate = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (_taskController.text.trim().isEmpty) return;

    final newTodo = Todo(
      id: widget.todoToEdit?.id,
      task: _taskController.text,
      startDate: _startDate,
      dueDate: _dueDate,
      status: _status,
      imagePath: _imagePath,
    );

    if (widget.todoToEdit == null) {
      await DatabaseHelper().insertTodo(newTodo);

      // Schedule notification in backend (Fire and forget, don't await)
      try {
        final prefs = await SharedPreferences.getInstance();
        final deviceId = prefs.getString('device_id');
        final baseUrl = dotenv.env['BACKEND_URL'];

        if (deviceId != null && baseUrl != null) {
          final url = Uri.parse('$baseUrl/api/notifications/schedule/todo/');
          final bodyPayload = jsonEncode({
            'notification': newTodo.task,
            'date_time': newTodo.startDate.toUtc().toIso8601String(),
            'device_id': deviceId,
          });

          // Unawaited to prevent UI blocking
          http
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: bodyPayload,
              )
              .timeout(
                const Duration(seconds: 10),
              )
              .then((response) {
            if (response.statusCode != 200 && response.statusCode != 201) {
              debugPrint(
                  'Backend notification schedule failed: ${response.body}');
            } else {
              debugPrint(
                  'Successfully scheduled backend notification for todo');
            }
          }).catchError((e) {
            debugPrint('Error scheduling todo notification: $e');
          });
        }
      } catch (e) {
        debugPrint('Error preparing todo notification: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A task todo is added')),
        );
      }
    } else {
      await DatabaseHelper().updateTodo(newTodo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully!')),
        );
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _formatDate(DateTime d) {
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EDCE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading:
            const BackButton(color: Color(0xFF3B4863)), // Needed for routing
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: const Icon(Icons.volunteer_activism,
                  color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Lifelog',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, size: 30, color: Color(0xFF3B4863)),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.settings),
            tooltip: 'Settings / Menu',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFD), // Clean white card
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
                // Header inside the card
                Row(
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
                                    offset: Offset(0, 2))
                              ]),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'TO DO LIST',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3B4863),
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Analyze Task',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B4863),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(
                    height: 1, thickness: 1.5, color: Color(0xFFDCDFD8)),
                const SizedBox(height: 24),

                // 'Add Your Task' Label
                Text(
                  widget.todoToEdit == null
                      ? 'Add Your Task'
                      : 'Edit Your Task',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3B4863)),
                ),
                const SizedBox(height: 12),

                // Text field Area
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A93A6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _taskController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'What need to be done?',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // DateTime / File Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDateTime(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFF3B4863), width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start',
                                  style: TextStyle(
                                      color: Color(0xFF3B4863),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_formatDate(_startDate),
                                  style: const TextStyle(
                                      color: Color(0xFF3B4863),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDateTime(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFF3B4863), width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Due',
                                  style: TextStyle(
                                      color: Color(0xFF3B4863),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_formatDate(_dueDate),
                                  style: const TextStyle(
                                      color: Color(0xFF3B4863),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8A93A6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imagePath == null
                            ? const Icon(Icons.attach_file, color: Colors.white)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(_imagePath!),
                                    fit: BoxFit.cover),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Add Task Action
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B4863),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                        widget.todoToEdit == null ? 'Add Task' : 'Update Task',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),

                // AI Response Area (Dashed Box)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      painter: DashedBorderPainter(
                          color: const Color(0xFF3B4863),
                          strokeWidth: 2,
                          gap: 5.0),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDAE3F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -12,
                      left: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDAE3F0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF3B4863),
                              width: 1.5,
                              style: BorderStyle.solid),
                        ),
                        child: const Text(
                          'AI Response',
                          style: TextStyle(
                              color: Color(0xFF3B4863),
                              fontWeight: FontWeight.w900,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save Action
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B4863),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Save',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),

                // History Title
                const Text(
                  'To Do History',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3B4863)),
                ),
                const SizedBox(height: 12),

                // History List Container
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A93A6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Created on',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text('Task',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_history.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('No history available.',
                              style: TextStyle(color: Colors.white70)),
                        ),
                      for (var item
                          in _history.take(10)) // show up to latest 10
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDate(item.startDate),
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              Text(
                                  item.task.length > 20
                                      ? '${item.task.substring(0, 18)}...'
                                      : item.task,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

