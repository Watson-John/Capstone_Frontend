import 'package:flutter/material.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/theme/app_theme.dart';
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
          final cs = Theme.of(context).colorScheme;
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
                              color: cs.surfaceContainer,
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
                                              color: cs.onSurfaceVariant,
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
                                                Navigator.pop(sheetContext);
                                              }
                                              onReload();
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
                                              onReload();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    if (todo.details != null &&
                                        todo.details!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        todo.details!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: cs.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
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
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: _statusCardColor(todo.status),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child:
                                              DropdownButtonHideUnderline(
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
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 10, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: _statusCardColor(v),
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: Text(v),
                                                          )))
                                                  .toList(),
                                              onChanged:
                                                  (String? newValue) async {
                                                if (newValue != null &&
                                                    newValue !=
                                                        todo.status) {
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
                                                                    'Changes saved successfully!')));
                                                  }
                                                  setModalState(() {
                                                    tasks[index] =
                                                        updatedTodo;
                                                  });
                                                  onReload();
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
