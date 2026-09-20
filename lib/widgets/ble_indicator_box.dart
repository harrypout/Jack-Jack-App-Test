import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IndicatorBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String asset;
  final Color? valueColor;
  const IndicatorBox({
    super.key,
    required this.title,
    required this.subtitle,
    required this.asset,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(14),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: ColorManager.white,
          border: Border.all(color: ColorManager.containerBorder),
          borderRadius: ThemeManager.brLg,
          boxShadow: ThemeManager.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                color: ColorManager.slate60,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: valueColor ?? ColorManager.slate,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  "assets/svgs/$asset.svg",
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    ColorManager.sage,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
