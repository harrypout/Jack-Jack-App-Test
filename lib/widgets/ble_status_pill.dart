import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';

enum PillTone {
  sage(background: ColorManager.sageTint10, foreground: ColorManager.sage),
  coral(
    background: ColorManager.coralTint10,
    foreground: ColorManager.coralIcon,
  );

  const PillTone({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

/// Tinted status pill ("Current", "Paired", "Streaming · 00:01:23").
class BLEStatusPill extends StatelessWidget {
  final String label;
  final PillTone tone;
  final bool leadingDot;

  const BLEStatusPill(
    this.label, {
    super.key,
    this.tone = PillTone.sage,
    this.leadingDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: ThemeManager.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tone.foreground,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
