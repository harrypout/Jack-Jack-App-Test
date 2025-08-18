import 'package:jackjack/utils/color_manager.dart';
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String section;
  final bool divider;
  final List<Widget> children;
  const SettingsSection({
    super.key,
    required this.section,
    this.divider = true,
    this.children = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        if(divider)
        Container(
          color: ColorManager.containerBorder,
      padding: EdgeInsets.only(top: 12),
      height: divider? 1:0,
        ),
        Text(
          section.toUpperCase(),
          style: const TextStyle(
            color: ColorManager.tertiaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        ...children,
      ],
    );
  }
}