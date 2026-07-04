import 'package:flutter/material.dart';
import 'package:jackjack/utils/color_manager.dart';

/// The design's "jjpulse" animation: stroked rings that scale 0.7→1.5 while
/// fading 0.9→0, each ring phase-shifted by [stagger]. Purely decorative.
class BLEPulseRings extends StatefulWidget {
  final int count;
  final double diameter;
  final Duration period;
  final Duration stagger;
  final Color color;
  final double strokeWidth;

  const BLEPulseRings({
    super.key,
    this.count = 2,
    required this.diameter,
    this.period = const Duration(milliseconds: 2400),
    this.stagger = const Duration(milliseconds: 1000),
    this.color = ColorManager.sageTint20,
    this.strokeWidth = 2,
  });

  @override
  State<BLEPulseRings> createState() => _BLEPulseRingsState();
}

class _BLEPulseRingsState extends State<BLEPulseRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rings scale up to 1.5× the base diameter; size the canvas to fit.
    final canvasSize = widget.diameter * 1.6;
    return SizedBox(
      width: canvasSize,
      height: canvasSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _PulseRingsPainter(
              t: _controller.value,
              count: widget.count,
              ringDiameter: widget.diameter,
              staggerFraction:
                  widget.stagger.inMilliseconds / widget.period.inMilliseconds,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _PulseRingsPainter extends CustomPainter {
  final double t;
  final int count;
  final double ringDiameter;
  final double staggerFraction;
  final Color color;
  final double strokeWidth;

  _PulseRingsPainter({
    required this.t,
    required this.count,
    required this.ringDiameter,
    required this.staggerFraction,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (var i = 0; i < count; i++) {
      final phase = (t - i * staggerFraction) % 1.0;
      final p = phase < 0 ? phase + 1.0 : phase;
      final scale = 0.7 + 0.8 * p;
      final opacity = 0.9 * (1.0 - p);
      paint.color = color.withValues(alpha: color.a * opacity);
      canvas.drawCircle(center, ringDiameter / 2 * scale, paint);
    }
  }

  @override
  bool shouldRepaint(_PulseRingsPainter oldDelegate) => oldDelegate.t != t;
}
