import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../expense_tracker/domain/models/category_styles.dart';
import '../../domain/models/todo_model.dart';

class TaskTimelineCard extends StatelessWidget {
  const TaskTimelineCard({
    super.key,
    required this.todo,
    required this.onTap,
    this.onSwipeLtr,
    this.onSwipeRtl,
    this.swipeLtrAction = 'complete',
    this.swipeRtlAction = 'complete',
  });

  final Todo todo;
  final VoidCallback onTap;
  final Future<bool> Function(Todo todo)? onSwipeLtr;
  final Future<bool> Function(Todo todo)? onSwipeRtl;
  final String swipeLtrAction;
  final String swipeRtlAction;

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

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _dateLine() {
    final sameDay = todo.startDate.year == todo.dueDate.year &&
        todo.startDate.month == todo.dueDate.month &&
        todo.startDate.day == todo.dueDate.day;
    return sameDay
        ? _fmtDate(todo.startDate)
        : '${_fmtDate(todo.startDate)} – ${_fmtDate(todo.dueDate)}';
  }

  String _timeLine() {
    return todo.isAllDay
        ? 'All Day'
        : '${_fmtTime(todo.startDate)} – ${_fmtTime(todo.dueDate)}';
  }

  static Color _actionColor(String action) {
    switch (action) {
      case 'complete':
        return const Color(0xFF5E9980); // matches AppTheme.accentGreen
      case 'in_progress':
        return const Color(0xFF8A4F00); // matches in-progress stripe
      case 'delete':
        return const Color(0xFFAD6464); // matches AppTheme.accentRed
      default:
        return const Color(0xFF5E9980);
    }
  }

  static IconData _actionIcon(String action) {
    switch (action) {
      case 'complete':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle_filled;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.check_circle;
    }
  }

  static String _actionLabel(String action) {
    switch (action) {
      case 'complete':
        return 'Complete';
      case 'in_progress':
        return 'In Progress';
      case 'delete':
        return 'Delete';
      default:
        return 'Complete';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasSwipe = onSwipeLtr != null || onSwipeRtl != null;

    Widget card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardChildBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status stripe
            Container(
              width: 4,
              height: 44,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: _statusStripe(cs),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          todo.task,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Color label dot
                      if (todo.category != null) ...[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: styleForCategory(todo.category!).background,
                            border: Border.all(
                              color: styleForCategory(todo.category!).foreground,
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (todo.isRecurring) ...[
                        Icon(Icons.repeat, size: 14, color: cs.onSurfaceVariant),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _dateLine(),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  Text(
                    _timeLine(),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusBg(cs),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                todo.status,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1C)),
              ),
            ),
          ],
        ),
      ),
    );

    if (!hasSwipe) return card;

    return Dismissible(
      key: ValueKey('todo-swipe-${todo.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && onSwipeLtr != null) {
          return onSwipeLtr!(todo);
        } else if (direction == DismissDirection.endToStart &&
            onSwipeRtl != null) {
          return onSwipeRtl!(todo);
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: _actionColor(swipeLtrAction),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(_actionIcon(swipeLtrAction), color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _actionLabel(swipeLtrAction),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: _actionColor(swipeRtlAction),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _actionLabel(swipeRtlAction),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Icon(_actionIcon(swipeRtlAction), color: Colors.white),
          ],
        ),
      ),
      child: card,
    );
  }
}
