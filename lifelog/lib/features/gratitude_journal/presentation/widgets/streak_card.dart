import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../mood_logger/presentation/widgets/mood_card_shell.dart';
import '../../domain/models/gratitude_entry.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.entries});

  final List<GratitudeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final current = _currentStreak(entries);
    final best = _bestStreak(entries);
    final total = entries.length;

    return MoodCardShell(
      title: 'Your Progress',
      child: Row(
        children: [
          _StatTile(
            emoji: '🔥',
            label: 'Streak',
            value: '$current',
            unit: current == 1 ? 'day' : 'days',
            accentColor: AppTheme.accentAmber.withValues(alpha: 0.15),
            valueColor: AppTheme.accentAmber,
            textTheme: textTheme,
            cs: cs,
          ),
          const SizedBox(width: 12),
          _StatTile(
            emoji: '⭐',
            label: 'Best',
            value: '$best',
            unit: best == 1 ? 'day' : 'days',
            accentColor: cs.primaryContainer,
            valueColor: cs.primary,
            textTheme: textTheme,
            cs: cs,
          ),
          const SizedBox(width: 12),
          _StatTile(
            emoji: '📖',
            label: 'Total',
            value: '$total',
            unit: total == 1 ? 'entry' : 'entries',
            accentColor: AppTheme.cardCompletedBg.withValues(alpha: 0.6),
            valueColor: AppTheme.accentGreen,
            textTheme: textTheme,
            cs: cs,
          ),
        ],
      ),
    );
  }

  static int _currentStreak(List<GratitudeEntry> entries) {
    if (entries.isEmpty) return 0;

    final today = _dateOnly(DateTime.now());
    final days = _uniqueDays(entries);

    if (!days.contains(today) && !days.contains(today.subtract(const Duration(days: 1)))) {
      return 0;
    }

    int streak = 0;
    DateTime cursor = days.contains(today) ? today : today.subtract(const Duration(days: 1));

    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _bestStreak(List<GratitudeEntry> entries) {
    if (entries.isEmpty) return 0;

    final days = _uniqueDays(entries).toList()..sort();
    if (days.isEmpty) return 0;

    int best = 1;
    int current = 1;

    for (int i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  static Set<DateTime> _uniqueDays(List<GratitudeEntry> entries) {
    return entries.map((e) => _dateOnly(DateTime.parse(e.dateTime))).toSet();
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
    required this.valueColor,
    required this.textTheme,
    required this.cs,
  });

  final String emoji;
  final String label;
  final String value;
  final String unit;
  final Color accentColor;
  final Color valueColor;
  final TextTheme textTheme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: valueColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
