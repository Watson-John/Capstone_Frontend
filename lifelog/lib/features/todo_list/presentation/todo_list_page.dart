import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/notif_test_button.dart';
import '../domain/models/todo_model.dart';
import 'widgets/schedule_card.dart';
import 'widgets/tasks_bottom_sheet.dart';
import 'widgets/todo_stats_card.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  TodoListPageState createState() => TodoListPageState();
}

class TodoListPageState extends State<TodoListPage> {
  /// Reload preferences and todos. Called externally when returning from settings.
  void refresh() => _loadTodos();

  List<Todo> _todos = [];

  // Cached swipe preferences
  String _swipeLtrAction = 'complete';
  String _swipeRtlAction = 'delete';

  @override
  void initState() {
    super.initState();
    _loadPrefsAndTodos();
  }

  Future<void> _loadPrefsAndTodos() async {
    final prefs = await SharedPreferences.getInstance();
    _swipeLtrAction = prefs.getString('swipe_ltr_action') ?? 'complete';
    _swipeRtlAction = prefs.getString('swipe_rtl_action') ?? 'delete';
    await _loadTodos();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final autoInProgress = prefs.getBool('auto_in_progress_enabled') ?? true;
    if (autoInProgress) {
      await DatabaseHelper().autoPromoteToInProgress();
    }
    _swipeLtrAction = prefs.getString('swipe_ltr_action') ?? 'complete';
    _swipeRtlAction = prefs.getString('swipe_rtl_action') ?? 'delete';

    final todos = await DatabaseHelper().getTodos();
    if (mounted) {
      setState(() => _todos = todos);
    }
  }

  Future<void> _navigateToAddTodo() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.addTodo);
    if (result == true) _loadTodos();
  }

  /// Returns true if the card should be dismissed (delete), false otherwise.
  Future<bool> _handleSwipeAction(Todo todo, String action) async {
    final db = DatabaseHelper();
    switch (action) {
      case 'complete':
        await db.updateTodo(todo.copyWith(status: 'Completed'));
        if (todo.id != null) {
          await LocalNotificationService.instance.cancelTaskReminder(todo.id!);
        }
        _loadTodos();
        return false;
      case 'in_progress':
        await db.updateTodo(todo.copyWith(status: 'In Progress'));
        _loadTodos();
        return false;
      case 'delete':
        await db.deleteTodo(todo.id!);
        await LocalNotificationService.instance.cancelTaskReminder(todo.id!);
        _loadTodos();
        return true;
      default:
        return false;
    }
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
                Row(
                  children: [
                    const Expanded(child: AppPageHeader(title: 'To-Do List')),
                    NotifTestButton(onPressed: () async {
                      await LocalNotificationService.instance
                          .showTestNotification('task');
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                ScheduleCard(
                  todos: _todos,
                  swipeLtrAction: _swipeLtrAction,
                  swipeRtlAction: _swipeRtlAction,
                  onSwipeAction: _handleSwipeAction,
                  onReload: _loadTodos,
                ),
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
}
