import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';

/// Uppercase section label with a 5px accent tick.
class BLEEyebrow extends StatelessWidget {
  final String label;
  final Color dotColor;

  const BLEEyebrow(
    this.label, {
    super.key,
    this.dotColor = ColorManager.yellowDot,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 6),
        Text(label.toUpperCase(), style: ThemeManager.eyebrow),
      ],
    );
  }
}
