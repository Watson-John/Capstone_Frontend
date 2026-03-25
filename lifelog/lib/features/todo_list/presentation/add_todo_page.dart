import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_helper.dart';
import '../domain/models/todo_model.dart';

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
  String? _imagePath;

  final ImagePicker _picker = ImagePicker();

  static const int _titleMaxLength = 50;

  @override
  void initState() {
    super.initState();
    if (widget.todoToEdit != null) {
      _titleController.text = widget.todoToEdit!.task;
      _detailsController.text = widget.todoToEdit!.details ?? '';
      _startDate = widget.todoToEdit!.startDate;
      _dueDate = widget.todoToEdit!.dueDate;
      _status = widget.todoToEdit!.status;
      _imagePath = widget.todoToEdit!.imagePath;
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
    );

    if (pickedDate != null) {
      if (!context.mounted) return;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
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
    if (_titleController.text.trim().isEmpty) return;

    final newTodo = Todo(
      id: widget.todoToEdit?.id,
      task: _titleController.text.trim(),
      details: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
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
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
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
            Text(
              'To-Do List',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            Text(
              isEditing ? 'Edit Task' : 'Add Task',
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                // Title label
                Text(
                  isEditing ? 'Edit Your Task' : 'Add Your Task',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Title field
                TextField(
                  controller: _titleController,
                  maxLength: _titleMaxLength,
                  maxLines: 1,
                  style: TextStyle(color: cs.onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'What needs to be done?',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                // Details field
                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  style: TextStyle(color: cs.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Details',
                    hintText: 'Add more details (optional)',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
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
                            border: Border.all(color: cs.outline, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(height: 4),
                              Text(_formatDate(_startDate),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w600,
                                  )),
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
                            border: Border.all(color: cs.outline, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Due',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(height: 4),
                              Text(_formatDate(_dueDate),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w600,
                                  )),
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
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _imagePath == null
                            ? Icon(Icons.attach_file,
                                color: cs.onSurfaceVariant)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(_imagePath!),
                                    fit: BoxFit.cover),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Add/Update Task Action
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _saveTask,
                    child: Text(
                        isEditing ? 'Update Task' : 'Add Task',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
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
