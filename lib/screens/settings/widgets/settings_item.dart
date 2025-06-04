import 'package:jackjack/utils/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SettingsItem extends StatelessWidget {
  final String assetName;
  final String title;
  final Widget? trailing;
  final void Function()? onTap;
  const SettingsItem({
    super.key,
    required this.assetName,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: ColorManager.tertiaryText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: SvgPicture.asset("assets/svgs/$assetName.svg"),
      trailing: trailing ?? SvgPicture.asset("assets/svgs/arrow-right.svg"),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}