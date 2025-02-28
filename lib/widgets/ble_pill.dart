import 'package:ble/utils/color_manager.dart';
import 'package:flutter/material.dart';

class BLEPill extends StatelessWidget {
  final Color color;
  const BLEPill({super.key, this.color = ColorManager.pill});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      width: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}