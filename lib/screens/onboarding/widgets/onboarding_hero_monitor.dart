import 'package:jackjack/screens/onboarding/widgets/onboarding_mini_card.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Page 3 hero: a mini "monitor" preview card — waveform + threshold track.
class OnboardingHeroMonitor extends StatelessWidget {
  const OnboardingHeroMonitor({super.key});

  static const _barHeights = [
    10.0, 16.0, 24.0, 34.0, 22.0, 14.0, 20.0, 30.0,
    40.0, 26.0, 16.0, 10.0, 18.0, 28.0, 20.0, 12.0,
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingMiniCard(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: ColorManager.sageTint10,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            "assets/svgs/microphone.svg",
            width: 30,
            height: 30,
            colorFilter: const ColorFilter.mode(
              ColorManager.sage,
              BlendMode.srcIn,
            ),
          ),
        ),
        Text("Quiet", style: ThemeManager.displaySub),
        SizedBox(
          height: 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < _barHeights.length; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Container(
                  width: 4,
                  height: _barHeights[i],
                  decoration: BoxDecoration(
                    color: (i > 7 && i < 11)
                        ? ColorManager.sage
                        : ColorManager.sageTint20,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 14,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: ColorManager.sageTint20,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth * 0.62 - 7,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorManager.sage,
                        boxShadow: ThemeManager.shadowSm,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
