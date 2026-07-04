import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/widgets/ble_pulse_rings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Scan/monitor hero: a sage disc with the glyph and the DS pulse rings.
/// With animate false the rings hold a static frame (no ticker), matching
/// the pre-redesign behaviour both call sites rely on.
class Scanner extends StatelessWidget {
  final String asset;
  final bool animate;

  const Scanner({super.key, required this.asset, this.animate = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          BLEPulseRings(
            count: 2,
            diameter: 78,
            period: const Duration(milliseconds: 2400),
            stagger: const Duration(milliseconds: 1200),
            animate: animate,
          ),
          Container(
            width: 118,
            height: 118,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ColorManager.sageTint10,
            ),
          ),
          SvgPicture.asset(
            "assets/svgs/$asset.svg",
            width: 40,
            height: 40,
            colorFilter: const ColorFilter.mode(
              ColorManager.sage,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
