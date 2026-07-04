import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SettingsItem extends StatelessWidget {
  final String assetName;
  final String title;
  final Color iconColor;
  final Widget? trailing;
  final void Function()? onTap;
  const SettingsItem({
    super.key,
    required this.assetName,
    required this.title,
    this.iconColor = ColorManager.slate60,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ThemeManager.rowLabel,
      ),
      leading: SvgPicture.asset(
        "assets/svgs/$assetName.svg",
        width: 18,
        height: 18,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
      trailing:
          trailing ??
          SvgPicture.asset(
            "assets/svgs/arrow-right.svg",
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              ColorManager.slate60,
              BlendMode.srcIn,
            ),
          ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      onTap: onTap,
    );
  }
}
