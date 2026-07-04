import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_eyebrow.dart';
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String section;
  final bool divider;
  final Color accentDot;
  final List<Widget> children;
  const SettingsSection({
    super.key,
    required this.section,
    this.divider = true,
    this.accentDot = ColorManager.yellowDot,
    this.children = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The old inter-section rule becomes breathing room above the label.
        SizedBox(height: divider ? 20 : 4),
        BLEEyebrow(section, dotColor: accentDot),
        const SizedBox(height: 8),
        Container(
          width: double.maxFinite,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: ColorManager.white,
            border: Border.all(color: ColorManager.containerBorder),
            borderRadius: ThemeManager.brLg,
            boxShadow: ThemeManager.shadowSm,
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Container(height: 1, color: ColorManager.containerBorder),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
