import 'package:ble/utils/color_manager.dart';
import 'package:ble/widgets/ble_bottom_sheet.dart';
import 'package:ble/widgets/device_info_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BluetoothDevice extends StatelessWidget {
  final String name;
  final bool isPaired;
  const BluetoothDevice({
    super.key,
    required this.name,
    required this.isPaired,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      // height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: ColorManager.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: ColorManager.containerBorder),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 12,
            children: [
              SvgPicture.asset("assets/svgs/device.svg"),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: ColorManager.primaryText,
                ),
              ),
            ],
          ),
          isPaired
              ? IconButton(
                onPressed: () {
                  BLEBottomSheet.openSheet(context, PairedInfoBottomSheet(name: name, isConnected: true, threshold: 80));
                },
                icon: SvgPicture.asset(
                  "assets/svgs/app-info.svg",
                  colorFilter: ColorFilter.mode(Colors.blue, BlendMode.srcIn),
                ),
              )
              : TextButton(
                onPressed: () {},
                child: Text(
                  "Pair",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: ColorManager.accent,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}