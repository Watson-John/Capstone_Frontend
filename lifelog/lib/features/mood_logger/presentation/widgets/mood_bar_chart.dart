import 'package:flutter/material.dart';

/// A reusable horizontal bar chart that renders labeled bars with counts.
///
/// Used for mood distribution, energy levels, and tag frequency.
class MoodBarChart extends StatelessWidget {
  const MoodBarChart({
    super.key,
    required this.data,
    required this.colorMap,
    this.iconMap,
  });

  /// Label → count (e.g. "great" → 5).
  final Map<String, int> data;

  /// Label → bar color.
  final Map<String, Color> colorMap;

  /// Optional label → emoji prefix shown before the label text.
  final Map<String, String>? iconMap;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No data yet.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final maxCount = data.values.fold(0, (a, b) => a > b ? a : b);

    // Sort descending by count.
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((entry) {
        final label = entry.key;
        final count = entry.value;
        final fraction = maxCount > 0 ? count / maxCount : 0.0;
        final color = colorMap[label] ?? cs.primaryContainer;
        final icon = iconMap?[label];

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Icon + label
              SizedBox(
                width: 90,
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Text(icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Bar
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth * fraction;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        height: 22,
                        width: barWidth.clamp(4.0, constraints.maxWidth),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Count
              SizedBox(
                width: 28,
                child: Text(
                  '$count',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
