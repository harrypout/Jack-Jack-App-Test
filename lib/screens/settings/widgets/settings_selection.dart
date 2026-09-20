import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_dropdown.dart';

class SettingsSelection<T> extends StatelessWidget {
  final String title;
  final String assetName;
  final Color iconColor;
  final Map<String, T> options;
  final T? value;
  final ValueChanged<T?> onSelected;

  const SettingsSelection({
    super.key,
    required this.title,
    required this.assetName,
    required this.iconColor,
    required this.options,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/svgs/$assetName.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: ThemeManager.rowLabel)),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder:
                (context, constraints) => DropdownWithMap<T>(
                  hintText: title,
                  items: options,
                  initialSelection: value,
                  width: constraints.maxWidth,
                  onSelected: onSelected,
                ),
          ),
        ],
      ),
    );
  }
}
