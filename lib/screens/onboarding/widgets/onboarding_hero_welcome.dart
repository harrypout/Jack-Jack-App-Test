import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/widgets/ble_pebble.dart';
import 'package:jackjack/widgets/ble_pulse_rings.dart';
import 'package:flutter/material.dart';

/// Page 1 hero: concentric pulse rings behind a sage disc and the Pebble.
class OnboardingHeroWelcome extends StatelessWidget {
  const OnboardingHeroWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const BLEPulseRings(
            count: 3,
            diameter: 96,
            period: Duration(milliseconds: 2600),
            stagger: Duration(milliseconds: 850),
          ),
          Container(
            width: 150,
            height: 150,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ColorManager.sageTint10,
            ),
          ),
          const BLEPebble(
            size: 92,
            fractions: pebbleFractionsOnboarding,
            shadow: [
              BoxShadow(
                color: Color(0x664A5568),
                offset: Offset(0, 10),
                blurRadius: 22,
                spreadRadius: -10,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
