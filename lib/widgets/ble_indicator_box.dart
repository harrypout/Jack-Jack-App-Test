import 'package:jackjack/utils/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IndicatorBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String asset;
  const IndicatorBox({
    super.key,
    required this.title,
    required this.subtitle,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.maxFinite,
        // height: 74,
        padding: const EdgeInsets.all(14),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: ColorManager.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: ColorManager.containerBorder),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: ColorManager.tertiaryText,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: ColorManager.quaternaryText,
                  ),
                ),
                SvgPicture.asset("assets/svgs/$asset.svg"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}