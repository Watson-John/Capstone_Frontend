import 'package:flutter/material.dart';

class EmptyTaskState extends StatelessWidget {
  const EmptyTaskState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.task_alt_outlined, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 10),
          Text(
            'No tasks for this day',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add one',
            style: TextStyle(color: cs.outline, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
