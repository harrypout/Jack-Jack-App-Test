import 'package:jackjack/screens/onboarding/widgets/onboarding_mini_card.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_pebble.dart';
import 'package:jackjack/widgets/ble_pulse_rings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Page 2 hero: a mini "pairing" preview card.
class OnboardingHeroConnect extends StatelessWidget {
  const OnboardingHeroConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingMiniCard(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const BLEPulseRings(
                count: 1,
                diameter: 66,
                period: Duration(milliseconds: 1800),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorManager.sageTint10,
                ),
              ),
              SvgPicture.asset(
                "assets/svgs/bluetooth.svg",
                width: 26,
                height: 26,
                colorFilter: const ColorFilter.mode(
                  ColorManager.sage,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
        Text(
          "Pebble found",
          style: GoogleFonts.fredoka(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: ColorManager.slate,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: ColorManager.background,
            border: Border.all(color: ColorManager.slate05),
            borderRadius: ThemeManager.brMd,
          ),
          child: Row(
            children: [
              const BLEPebble(size: 26),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "The Pebble",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: ColorManager.slate,
                      ),
                    ),
                    Text(
                      "Signal strong · 82%",
                      style: TextStyle(
                        fontSize: 9.5,
                        color: ColorManager.slate60,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: ColorManager.sage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
