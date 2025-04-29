import 'package:ble/providers/connected_devices_provider.dart';
import 'package:ble/screens/pairing/pods/available_devices.dart';
import 'package:ble/screens/pairing/pods/paired_devices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:ble/widgets/ble_bottom_sheet.dart';
import 'package:ble/screens/pairing/widgets/device_info_bottom_sheet.dart';

class BluetoothDeviceWidget extends ConsumerWidget {
  final BluetoothDevice device;
  final bool isPaired;
  final void Function(BluetoothDevice device)? onConnect;
  const BluetoothDeviceWidget({
    super.key,
    required this.device,
    required this.isPaired,
     this.onConnect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.maxFinite,
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
            children: [
              SvgPicture.asset("assets/svgs/device.svg"),
              const SizedBox(width: 12),
              Text(
                device.platformName ?? "Unknown Device",
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
                  BLEBottomSheet.openSheet(
                    context,
                    PairedInfoBottomSheet(
                      device: device,
                    ),
                  );
                },
                icon: SvgPicture.asset(
                  "assets/svgs/app-info.svg",
                  colorFilter: ColorFilter.mode(Colors.blue, BlendMode.srcIn),
                ),
              )
              : TextButton(
                onPressed: () {
                  if(onConnect != null) {
                    onConnect!(device);
                  }
                },
                child: Text(
                  "Connect",
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
