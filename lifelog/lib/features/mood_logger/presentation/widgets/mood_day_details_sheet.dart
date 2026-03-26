import 'package:flutter/material.dart';

import '../../domain/models/mood_log.dart';
import '../../domain/models/mood_tag_styles.dart';
import 'mood_details_bottom_sheet.dart';

/// Shows a bottom sheet listing all mood logs for a given day.
/// Tapping an entry opens the existing single-log detail sheet.
void showMoodDayDetailsSheet(
  BuildContext context, {
  required DateTime date,
  required List<MoodLog> logs,
  required VoidCallback onReload,
}) {
  final cs = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  final monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: cs.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Date header ──────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                '${monthNames[date.month - 1]} ${date.day}, ${date.year}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              Text(
                '${logs.length} ${logs.length == 1 ? 'entry' : 'entries'}',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // ── Log list ─────────────────────────────────────────────
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final log = logs[index];
                    final dt = DateTime.parse(log.dateTime);
                    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
                    final time =
                        '$hour:${dt.minute.toString().padLeft(2, '0')} '
                        '${dt.hour >= 12 ? 'PM' : 'AM'}';

                    final tags = (log.tags != null && log.tags!.isNotEmpty)
                        ? log.tags!.split(',')
                        : <String>[];

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        showMoodDetailsBottomSheet(
                          context,
                          log: log,
                          onReload: onReload,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Emoji
                            CircleAvatar(
                              backgroundColor: cs.surfaceContainer,
                              radius: 20,
                              child: Text(log.emoji,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mood label + energy
                                  Row(
                                    children: [
                                      Text(
                                        log.mood,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      if (log.energy != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: kEnergyColors[log.energy] ??
                                                cs.surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            log.energy!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  // Tags row
                                  if (tags.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: tags.map((tag) {
                                        final style = kTagStyles[tag];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: style?.background ??
                                                cs.surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            tag,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: style?.foreground ??
                                                  cs.onSurfaceVariant,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],

                                  // Note preview
                                  if (log.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      log.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Time
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
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
        ),
      );
    },
  );
}
