import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/todo_model.dart';

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
      default:
        return AppTheme.cardToDoBg;
    }
  }

  Color _statusFg(ColorScheme cs) {
    return const Color(0xFF1C1C1C);
  }

  Color _statusStripe(ColorScheme cs) {
    switch (todo.status) {
      case 'Completed':
        return AppTheme.accentGreen;
      case 'In Progress':
        return const Color(0xFF8A4F00);
      default:
        return AppTheme.accentRed;
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
          color: AppTheme.cardChildBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _statusStripe(cs),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
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
