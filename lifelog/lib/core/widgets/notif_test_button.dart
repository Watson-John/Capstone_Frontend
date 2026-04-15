import 'package:flutter/material.dart';

/// A small icon button used to preview a scheduled notification.
/// Extracted from todo_list_page.dart and gratitude_journal_page.dart.
class NotifTestButton extends StatelessWidget {
  const NotifTestButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Preview notification',
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.notifications_outlined, color: cs.onSurfaceVariant),
        style: IconButton.styleFrom(
          backgroundColor: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
