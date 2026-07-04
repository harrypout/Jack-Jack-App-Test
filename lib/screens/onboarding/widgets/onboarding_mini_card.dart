import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';

/// Floating preview card used by the onboarding heroes.
class OnboardingMiniCard extends StatelessWidget {
  final List<Widget> children;

  const OnboardingMiniCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: ColorManager.white,
        border: Border.all(color: ColorManager.slate05),
        borderRadius: ThemeManager.brXl,
        boxShadow: ThemeManager.miniCardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ),
    );
  }
}
