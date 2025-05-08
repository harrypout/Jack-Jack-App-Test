import 'package:ble/providers/device_threshold_provider.dart';
import 'package:ble/providers/connected_devices_provider.dart';
import 'package:ble/screens/pairing/pods/available_devices.dart';
import 'package:ble/screens/pairing/pods/paired_devices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:ble/widgets/ble_bottom_sheet.dart';
import 'package:ble/widgets/ble_filled_button.dart';
import 'package:ble/widgets/ble_outlined_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main.dart';

class PairedInfoBottomSheet extends ConsumerWidget {
  final BluetoothDevice device;
  const PairedInfoBottomSheet({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threshold = ref.watch(deviceThresholdProvider(device.remoteId.str));
    return BLEBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device.platformName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: ColorManager.primaryText,
            ),
          ),
          Text(
            "View details of your connected device",
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: ColorManager.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.maxFinite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: ColorManager.greyContainerBackground,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: ColorManager.containerBorder),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Device Name",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: ColorManager.secondaryText,
                        ),
                      ),
                      Text(
                        device.platformName,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: ColorManager.tertiaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  width: MediaQuery.of(context).size.width * 0.8,
                  color: ColorManager.containerBorder,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Status",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: ColorManager.secondaryText,
                        ),
                      ),
                      Text(
                        device.isConnected ? "Connected" : "Disconnected",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: ColorManager.tertiaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  width: MediaQuery.of(context).size.width * 0.8,
                  color: ColorManager.containerBorder,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sound Threshold",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: ColorManager.secondaryText,
                        ),
                      ),
                      Text(
                        threshold!= null?"$threshold dB":"Not Available",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: ColorManager.tertiaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 16,
              children: [
                Expanded(
                  child: BLEOutlinedButton(
                    data: "Cancel",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    maxButton: true,
                  ),
                ),
                Expanded(
                  child: BLEFilledButton(
                    data: "Forget Device",
                    onPressed: () async {
                      List<String> list =
                          prefs.getStringList('pairedDevicesUUID') ?? [];
                      list.remove(device.remoteId.str);
                      await prefs.setStringList('pairedDevicesUUID', list);
                      await device.removeBond();
                      await device.disconnect();
                      ref.read(availableDevicesProvider.notifier).refresh();
                      ref.invalidate(pairedDevicesProvider);
                      ref.invalidate(connectedDevicesProvider);
                      Navigator.pop(context);
                    },
                    maxButton: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
