import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/todo_model.dart';

class TodoStatsCard extends StatelessWidget {
  const TodoStatsCard({
    super.key,
    required this.todos,
    required this.onCategoryTap,
  });

  final List<Todo> todos;
  final void Function(String title, List<Todo> tasks) onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final int total = todos.length;
    final int todoCount = todos.where((t) => t.status == 'To Do').length;
    final int inProgressCount =
        todos.where((t) => t.status == 'In Progress').length;
    final int completedCount =
        todos.where((t) => t.status == 'Completed').length;

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
          _StatCell(
            title: 'Total',
            count: total.toString(),
            bgColor: AppTheme.cardTotalBg,
            textColor: cs.onSurface,
            onTap: () => onCategoryTap('Total', todos),
          ),
          _StatCell(
            title: 'To Do',
            count: todoCount.toString(),
            bgColor: AppTheme.cardToDoBg,
            textColor: cs.onSurface,
            onTap: () => onCategoryTap(
                'To Do', todos.where((t) => t.status == 'To Do').toList()),
          ),
          _StatCell(
            title: 'In Progress',
            count: inProgressCount.toString(),
            bgColor: AppTheme.cardInProgressBg,
            textColor: cs.onSurface,
            onTap: () => onCategoryTap('In Progress',
                todos.where((t) => t.status == 'In Progress').toList()),
          ),
          _StatCell(
            title: 'Completed',
            count: completedCount.toString(),
            bgColor: AppTheme.cardCompletedBg,
            textColor: cs.onSurface,
            onTap: () => onCategoryTap('Completed',
                todos.where((t) => t.status == 'Completed').toList()),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.title,
    required this.count,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  final String title;
  final String count;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
}
