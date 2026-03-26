import 'package:flutter/material.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../expense_tracker/domain/models/category_styles.dart';
import '../../domain/models/todo_model.dart';
import '../add_todo_page.dart';

Color _statusCardColor(String status) {
  switch (status) {
    case 'Completed':
      return AppTheme.cardCompletedBg;
    case 'In Progress':
      return AppTheme.cardInProgressBg;
    default:
      return AppTheme.cardToDoBg;
  }
}

void showTasksBottomSheet(
  BuildContext context, {
  required String title,
  required List<Todo> tasks,
  required VoidCallback onReload,
}) {
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
                      ? const Center(child: Text('No tasks in this category.'))
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final todo = tasks[index];
                            return _TaskCard(
                              todo: todo,
                              onStatusChanged: (updatedTodo) {
                                setModalState(() => tasks[index] = updatedTodo);
                                onReload();
                              },
                              onEdit: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddTodoPage(todoToEdit: todo),
                                  ),
                                );
                                if (updated == true) {
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                  onReload();
                                }
                              },
                              onDelete: () async {
                                if (todo.id != null) {
                                  await DatabaseHelper().deleteTodo(todo.id!);
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Task deleted successfully!')));
                                  }
                                  onReload();
                                }
                              },
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

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.todo,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final Todo todo;
  final ValueChanged<Todo> onStatusChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cs.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title + color dot + Edit/Delete ──────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todo.category != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: styleForCategory(todo.category!).background,
                        border: Border.all(
                          color: styleForCategory(todo.category!).foreground,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Text(
                    todo.task,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.onSurface),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: cs.onSurfaceVariant, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: cs.error, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
              ],
            ),

            // ── Details ───────────────────────────────────────────────
            if (todo.details != null && todo.details!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                todo.details!,
                style: TextStyle(
                    fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
              ),
            ],

            // ── Metadata chips ────────────────────────────────────────
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _metaChip(
                  context,
                  icon: Icons.schedule,
                  label: todo.isAllDay
                      ? 'All Day · ${_fmtDate(todo.startDate)}'
                      : '${_fmtDate(todo.startDate)} → ${_fmtDate(todo.dueDate)}',
                ),
                if (todo.reminderMinutes != null)
                  _metaChip(
                    context,
                    icon: Icons.notifications_none,
                    label: _fmtReminder(todo.reminderMinutes!),
                  ),
                if (todo.isRecurring)
                  _metaChip(
                    context,
                    icon: Icons.repeat,
                    label: _fmtRecurrence(todo),
                  ),
              ],
            ),

            // ── Status dropdown ───────────────────────────────────────
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface)),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _statusCardColor(todo.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: todo.status,
                      icon: Icon(Icons.arrow_drop_down, color: cs.primary),
                      style: TextStyle(
                          color: cs.onSurface, fontWeight: FontWeight.bold),
                      items: const ['To Do', 'In Progress', 'Completed']
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusCardColor(v),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(v),
                                ),
                              ))
                          .toList(),
                      onChanged: (String? newValue) async {
                        if (newValue != null && newValue != todo.status) {
                          final updatedTodo = todo.copyWith(status: newValue);
                          await DatabaseHelper().updateTodo(updatedTodo);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Changes saved successfully!')));
                          }
                          onStatusChanged(updatedTodo);
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
  }

  Widget _metaChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

String _fmtReminder(int minutes) {
  if (minutes == 0) return 'At time';
  if (minutes == 1440) return '1 day before';
  if (minutes >= 60) return '${minutes ~/ 60} hr before';
  return '$minutes min before';
}

String _fmtRecurrence(Todo todo) {
  if (todo.recurrenceType == null) return 'Recurring';
  final type =
      todo.recurrenceType![0].toUpperCase() + todo.recurrenceType!.substring(1);
  if (todo.recurrenceType == 'weekly' &&
      todo.recurrenceDays != null &&
      todo.recurrenceDays!.isNotEmpty) {
    return '$type · ${todo.recurrenceDays}';
  }
  return type;
}
