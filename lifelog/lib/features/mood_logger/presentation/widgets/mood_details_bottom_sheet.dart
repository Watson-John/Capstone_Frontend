import 'package:flutter/material.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/models/mood_log.dart';
import '../add_mood_page.dart';

void showMoodDetailsBottomSheet(
  BuildContext context, {
  required MoodLog log,
  required VoidCallback onReload,
}) {
  final cs = Theme.of(context).colorScheme;
  final dt = DateTime.parse(log.dateTime);
  final formattedDate =
      '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final formattedTime =
      '$hour:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';

  showModalBottomSheet(
    context: context,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(log.emoji,
                          style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          log.mood,
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(
                            fontSize: 12, color: cs.outline),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  log.description,
                  style: TextStyle(
                      fontSize: 14, color: cs.onSurface, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddMoodPage(moodToEdit: log),
                          ),
                        );
                        if (result == true) onReload();
                      },
                      icon: Icon(Icons.edit,
                          color: cs.primary, size: 18),
                      label: Text('Edit',
                          style: TextStyle(color: cs.primary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.primary),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _confirmDelete(context, log, onReload);
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 18),
                      label: const Text('Delete',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
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
  );
}

void _confirmDelete(
    BuildContext context, MoodLog log, VoidCallback onReload) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete Mood Log?'),
      content: const Text(
          'Are you sure you want to permanently delete this mood entry?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            if (log.id != null) {
              final messenger = ScaffoldMessenger.of(context);
              await DatabaseHelper().deleteMoodLog(log.id!);
              onReload();
              if (context.mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Mood log deleted')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
