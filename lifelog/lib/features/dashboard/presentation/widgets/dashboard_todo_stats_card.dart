import 'package:flutter/material.dart';

import '../../../../core/database/database_helper.dart';
import '../../../todo_list/domain/models/todo_model.dart';
import '../../../todo_list/presentation/widgets/tasks_bottom_sheet.dart';
import '../../../todo_list/presentation/widgets/todo_stats_card.dart';

/// Self-fetching card that renders the TodoStatsCard with live data.
class DashboardTodoStatsCard extends StatefulWidget {
  const DashboardTodoStatsCard({super.key});

  @override
  State<DashboardTodoStatsCard> createState() => _DashboardTodoStatsCardState();
}

class _DashboardTodoStatsCardState extends State<DashboardTodoStatsCard> {
  bool _isLoading = true;
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final todos = await DatabaseHelper().getTodos();
    if (mounted) {
      setState(() {
        _todos = todos;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return TodoStatsCard(
      todos: _todos,
      onCategoryTap: (title, tasks) => showTasksBottomSheet(
        context,
        title: title,
        tasks: tasks,
        onReload: _load,
      ),
    );
  }
}
