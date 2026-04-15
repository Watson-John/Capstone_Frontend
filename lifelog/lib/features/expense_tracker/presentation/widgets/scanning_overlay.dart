import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/widgets/expressive_squiggle_progress_bar.dart';
import '../../data/expense_service.dart';

class ScanningOverlay extends StatelessWidget {
  const ScanningOverlay({
    super.key,
    required this.progress,
    required this.scanStage,
    required this.scanAnimation,
  });

  final double progress;
  final ReceiptScanStage scanStage;
  final Animation<double> scanAnimation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const steps = ['Scanning receipt', 'Analyzing image', 'Extracting data'];

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        color: cs.scrim.withValues(alpha: 0.45),
        child: Center(
          child: AnimatedBuilder(
            animation: scanAnimation,
            builder: (context, _) {
              final stepIndex = scanStage == ReceiptScanStage.uploading
                  ? 0
                  : scanStage == ReceiptScanStage.processing
                      ? 1
                      : 2;
              final dotCount = (scanAnimation.value * 3).floor() % 4;
              final dots = '.' * dotCount;
              final pulse = 0.92 + 0.08 * math.sin(scanAnimation.value * 2 * math.pi);
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                color: cs.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: pulse,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.document_scanner_rounded,
                            size: 36,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 220,
                        child: ExpressiveSquiggleProgressBar(
                          value: progress,
                          color: cs.primary,
                          trackColor: cs.primaryContainer,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${steps[stepIndex]}$dots',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
