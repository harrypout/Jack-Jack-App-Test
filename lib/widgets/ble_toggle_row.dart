import 'package:flutter/material.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/widgets/ble_toggle.dart';

class BleToggleRow extends StatelessWidget {
  final String data;
  final bool value;
  final Function(bool)? onChanged;
  const BleToggleRow(
    this.data, {
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          data,
          style: const TextStyle(
            color: ColorManager.secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        BLEToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}
