import 'package:ble/utils/color_manager.dart';
import 'package:flutter/material.dart';

class BLEToggle extends StatelessWidget {
  final bool value;
  final void Function(bool)? onChanged;
  const BLEToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      activeColor: ColorManager.white,
      activeTrackColor: ColorManager.accent,
      inactiveThumbColor: ColorManager.white,
      inactiveTrackColor: ColorManager.containerBorder,
      trackOutlineWidth: WidgetStatePropertyAll(0.00000000001),
      trackOutlineColor: WidgetStatePropertyAll(ColorManager.containerBorder),
      onChanged: onChanged,
    );
  }
}