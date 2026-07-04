import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/widgets/ble_pulse_rings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Scan/monitor hero: a sage disc with the glyph and pulsing DS rings.
class Scanner extends StatelessWidget {
  final String asset;
  // Kept for call-site compatibility; the DS hero rings always pulse.
  final bool animate;

  const Scanner({super.key, required this.asset, this.animate = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const BLEPulseRings(
            count: 2,
            diameter: 78,
            period: Duration(milliseconds: 2400),
            stagger: Duration(milliseconds: 1200),
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
