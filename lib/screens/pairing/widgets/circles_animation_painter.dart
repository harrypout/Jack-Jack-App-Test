// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class CirclesAnimationPainter extends CustomPainter {
  final double innerRadius;
  final double middleRadius;
  final double outerRadius;
  final Color color;

  CirclesAnimationPainter({
    required this.innerRadius,
    required this.middleRadius,
    required this.outerRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw circles from largest to smallest
    _drawCircle(canvas, center, outerRadius, color.withOpacity(0.1));
    _drawCircle(canvas, center, middleRadius, color.withOpacity(0.2));
    _drawCircle(canvas, center, innerRadius, color.withOpacity(1));
  }

  void _drawCircle(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(CirclesAnimationPainter oldDelegate) {
    return innerRadius != oldDelegate.innerRadius ||
        middleRadius != oldDelegate.middleRadius ||
        outerRadius != oldDelegate.outerRadius;
  }
}