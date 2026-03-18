import 'dart:math' as math;

import 'package:flutter/material.dart';

// ── Public widget ──────────────────────────────────────────────────────────────

/// Material 3 Expressive-style **determinate** linear progress bar.
///
/// Reproduces the "flat and wavy" indicator from stock Google apps:
///
///   [▓▓▓ wavy active ▓▓▓]  ·  [ flat track ─────── • ]
///
/// The [value] (0.0 – 1.0) controls how much of the bar is filled with the
/// wavy active portion. Value changes are implicitly animated over 300 ms.
/// The wave rolls forward continuously regardless of value.
///
/// ```dart
/// ExpressiveSquiggleProgressBar(value: 0.6)
/// ```
class ExpressiveSquiggleProgressBar extends StatefulWidget {
  /// Current progress, from 0.0 (empty) to 1.0 (full). Changes are implicitly
  /// animated with [Curves.easeInOut] over 300 ms.
  final double value;

  /// Total widget height **including wave headroom**. The flat-track body
  /// thickness is derived as `height − 2 × amplitude`. Defaults to [10.0].
  final double height;

  /// Peak-to-centre wave deflection in logical pixels. Defaults to [2.0].
  final double amplitude;

  /// Pixel distance between consecutive wave crests. Defaults to [40.0].
  final double wavelength;

  /// Wave-roll speed multiplier. [1.0] = default tempo. Defaults to [1.0].
  final double speed;

  /// Active indicator colour. Falls back to [ColorScheme.primary].
  final Color? color;

  /// Inactive track colour. Falls back to [ColorScheme.secondaryContainer].
  final Color? trackColor;

  /// Optional outer padding applied around the bar.
  final EdgeInsetsGeometry? padding;

  /// Semantic label announced by screen readers. Defaults to `'Loading'`.
  final String semanticsLabel;

  const ExpressiveSquiggleProgressBar({
    super.key,
    required this.value,
    this.height = 10.0,
    this.amplitude = 2.0,
    this.wavelength = 40.0,
    this.speed = 1.0,
    this.color,
    this.trackColor,
    this.padding,
    this.semanticsLabel = 'Loading',
  });

  @override
  State<ExpressiveSquiggleProgressBar> createState() =>
      _ExpressiveSquiggleProgressBarState();
}

class _ExpressiveSquiggleProgressBarState
    extends State<ExpressiveSquiggleProgressBar>
    with TickerProviderStateMixin {
  // Rolls the sine wave forward continuously.
  late AnimationController _waveController;

  // Smoothly tweens between value changes (implicit animation).
  late AnimationController _valueController;
  late Tween<double> _valueTween;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (800 / widget.speed).round()),
    )..repeat();

    _valueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _valueTween = Tween<double>(
      begin: widget.value,
      end: widget.value,
    );
  }

  @override
  void didUpdateWidget(ExpressiveSquiggleProgressBar old) {
    super.didUpdateWidget(old);
    if (old.speed != widget.speed) {
      _waveController
        ..duration = Duration(milliseconds: (800 / widget.speed).round())
        ..repeat();
    }
    if (old.value != widget.value) {
      _valueTween = Tween<double>(
        begin: _animatedValue,
        end: widget.value,
      );
      _valueController.forward(from: 0);
    }
  }

  double get _animatedValue => _valueTween.evaluate(
        CurvedAnimation(parent: _valueController, curve: Curves.easeInOut),
      );

  @override
  void dispose() {
    _waveController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = widget.color ?? cs.primary;
    final effectiveTrack = widget.trackColor ?? cs.secondaryContainer;

    Widget bar = AnimatedBuilder(
      animation: Listenable.merge([_waveController, _valueController]),
      builder: (_, __) => CustomPaint(
        size: Size.fromHeight(widget.height),
        painter: _SquigglePainter(
          value: _animatedValue.clamp(0.0, 1.0),
          wavePhase: _waveController.value,
          color: effectiveColor,
          trackColor: effectiveTrack,
          amplitude: widget.amplitude,
          wavelength: widget.wavelength,
        ),
      ),
    );

    if (widget.padding != null) {
      bar = Padding(padding: widget.padding!, child: bar);
    }

    return Semantics(
      label: widget.semanticsLabel,
      value: '${(widget.value * 100).round()}%',
      child: bar,
    );
  }
}

// ── Painter ────────────────────────────────────────────────────────────────────

class _SquigglePainter extends CustomPainter {
  final double value;     // 0.0 – 1.0 : fill level
  final double wavePhase; // 0 → 1 : continuous wave roll
  final Color color;
  final Color trackColor;
  final double amplitude;
  final double wavelength;

  const _SquigglePainter({
    required this.value,
    required this.wavePhase,
    required this.color,
    required this.trackColor,
    required this.amplitude,
    required this.wavelength,
  });

  // M3 spec: 4 dp gap between indicator and track.
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;

    // Body thickness = track height = wave stroke width.
    final bodyH = math.max(size.height - 2 * amplitude, 2.0);
    final bodyHalf = bodyH / 2;

    // ── Wave endpoint ────────────────────────────────────────────────────────
    //
    // The wave path runs from x = 0 to x = waveEnd. StrokeCap.round adds
    // bodyHalf beyond the endpoint, so the visual right edge is
    // waveEnd + bodyHalf. At value = 1 the visual edge reaches size.width.
    final waveEnd = value * (size.width - bodyHalf);

    // Visual right edge of the wave (including round cap).
    final visualEnd = waveEnd + bodyHalf;

    // ── 1. Flat track ────────────────────────────────────────────────────────
    final trackStart = visualEnd + _gap;
    if (trackStart < size.width && value < 1.0) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          trackStart,
          mid - bodyHalf,
          size.width,
          mid + bodyHalf,
          Radius.circular(bodyHalf),
        ),
        Paint()..color = trackColor,
      );

      // ── 2. Stop indicator dot ──────────────────────────────────────────────
      final dotR = bodyH * 0.22;
      canvas.drawCircle(
        Offset(size.width - bodyHalf, mid),
        dotR,
        Paint()..color = color,
      );
    }

    // ── 3. Wavy active portion ───────────────────────────────────────────────
    if (waveEnd > 1) {
      final wavePath = Path();
      for (double x = 0; x <= waveEnd; x++) {
        final y = mid +
            amplitude *
                math.sin((x / wavelength - wavePhase) * 2 * math.pi);
        if (x == 0) {
          wavePath.moveTo(x, y);
        } else {
          wavePath.lineTo(x, y);
        }
      }

      canvas.drawPath(
        wavePath,
        Paint()
          ..color = color
          ..strokeWidth = bodyH
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_SquigglePainter old) =>
      value != old.value ||
      wavePhase != old.wavePhase ||
      color != old.color ||
      trackColor != old.trackColor ||
      amplitude != old.amplitude ||
      wavelength != old.wavelength;
}
