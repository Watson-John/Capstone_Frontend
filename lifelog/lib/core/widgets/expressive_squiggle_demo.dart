import 'package:flutter/material.dart';

import 'expressive_squiggle_progress_bar.dart';

// ── Demo page ──────────────────────────────────────────────────────────────────

class ExpressiveSquiggleDemoPage extends StatefulWidget {
  const ExpressiveSquiggleDemoPage({super.key});

  @override
  State<ExpressiveSquiggleDemoPage> createState() =>
      _ExpressiveSquiggleDemoPageState();
}

class _ExpressiveSquiggleDemoPageState
    extends State<ExpressiveSquiggleDemoPage> {
  double _sliderValue = 0.6;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'M3 Expressive Progress Bar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Interactive slider ──────────────────────────────────────────────
          Card(
            color: cs.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interactive  (${(_sliderValue * 100).round()} %)',
                    style: tt.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Drag the slider — value changes animate smoothly.',
                    style:
                        tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  ExpressiveSquiggleProgressBar(value: _sliderValue),
                  Slider(
                    value: _sliderValue,
                    onChanged: (v) => setState(() => _sliderValue = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Fixed values ───────────────────────────────────────────────────
          _SectionCard(
            label: '25 %',
            description: 'value: 0.25',
            child: const ExpressiveSquiggleProgressBar(value: 0.25),
          ),
          const SizedBox(height: 12),

          _SectionCard(
            label: '50 %',
            description: 'value: 0.50',
            child: const ExpressiveSquiggleProgressBar(value: 0.50),
          ),
          const SizedBox(height: 12),

          _SectionCard(
            label: '90 %',
            description: 'value: 0.90',
            child: const ExpressiveSquiggleProgressBar(value: 0.90),
          ),
          const SizedBox(height: 12),

          // ── Compact ────────────────────────────────────────────────────────
          _SectionCard(
            label: 'Compact  (8 dp)',
            description: 'height: 8, amplitude: 1.5',
            child: const ExpressiveSquiggleProgressBar(
              value: 0.6,
              height: 8,
              amplitude: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // ── Tall ───────────────────────────────────────────────────────────
          _SectionCard(
            label: 'Tall  (14 dp)',
            description: 'height: 14, amplitude: 3.0, wavelength: 48',
            child: const ExpressiveSquiggleProgressBar(
              value: 0.65,
              height: 14,
              amplitude: 3.0,
              wavelength: 48,
            ),
          ),
          const SizedBox(height: 12),

          // ── Colour roles ───────────────────────────────────────────────────
          _SectionCard(
            label: 'Tertiary colour role',
            description: 'tertiary / tertiaryContainer',
            child: ExpressiveSquiggleProgressBar(
              value: 0.55,
              color: cs.tertiary,
              trackColor: cs.tertiaryContainer,
            ),
          ),
          const SizedBox(height: 12),

          // ── Context simulation ─────────────────────────────────────────────
          _ContextCard(label: 'Scanning overlay simulation'),
          const SizedBox(height: 12),

          // ── Notes ──────────────────────────────────────────────────────────
          Card(
            color: cs.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How it works', style: tt.titleSmall),
                  const SizedBox(height: 8),
                  _Note(
                    '• Determinate: accepts a value (0.0–1.0). Value changes '
                    'are implicitly animated over 300 ms with easeInOut.',
                  ),
                  _Note(
                    '• Wave roll: a separate 800 ms looping '
                    'AnimationController rolls the sine phase forward '
                    'continuously, keeping the wave alive even when the '
                    'value is static.',
                  ),
                  _Note(
                    '• The wave is a thick stroked sine path with '
                    'StrokeCap.round. strokeWidth = bodyH '
                    '(height − 2 × amplitude), matching the flat track '
                    'thickness.',
                  ),
                  _Note(
                    '• 4 dp gap + stop-indicator dot between the active '
                    'wave and the flat track, per M3 2024 spec.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String label;
  final String description;
  final Widget child;

  const _SectionCard({
    required this.label,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      color: cs.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: tt.labelLarge),
            const SizedBox(height: 2),
            Text(
              description,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  final String label;
  const _ContextCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Text(label, style: tt.labelLarge),
            const SizedBox(height: 24),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_rounded,
                size: 28,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ExpressiveSquiggleProgressBar(
                value: 0.65,
                color: cs.primary,
                trackColor: cs.primaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scanning receipt\u2026',
              style: tt.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
      ),
    );
  }
}
