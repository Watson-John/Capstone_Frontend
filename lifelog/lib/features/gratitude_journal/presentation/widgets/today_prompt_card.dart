import 'package:flutter/material.dart';

class TodayPromptCard extends StatelessWidget {
  const TodayPromptCard({
    super.key,
    required this.prompt,
    required this.hasEntryToday,
    required this.onWriteTap,
  });

  final String prompt;
  final bool hasEntryToday;
  final VoidCallback onWriteTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Today\'s Prompt',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              if (hasEntryToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Written',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (prompt.isEmpty)
            _PromptSkeleton(cs: cs)
          else
            Text(
              prompt,
              style: textTheme.bodyLarge?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: hasEntryToday
                ? OutlinedButton.icon(
                    onPressed: onWriteTap,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Write another entry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: onWriteTap,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text(
                      'Write Today\'s Entry',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Loading skeleton for prompt ───────────────────────────────────────────────

class _PromptSkeleton extends StatelessWidget {
  const _PromptSkeleton({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 14,
          width: double.infinity,
          decoration: BoxDecoration(
            color: cs.onPrimaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 14,
          width: 200,
          decoration: BoxDecoration(
            color: cs.onPrimaryContainer.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}
