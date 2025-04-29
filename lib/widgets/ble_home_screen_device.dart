import 'package:ble/models/ble_device.dart';
import 'package:ble/providers/device_threshold_provider.dart';
import 'package:ble/providers/selected_device_provider.dart';
import 'package:ble/providers/connected_devices_provider.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:ble/widgets/ble_pill.dart';
import 'package:ble/widgets/ble_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreenDevice extends ConsumerStatefulWidget {
  final BLEDevice device;
  final bool isSelected;

  const HomeScreenDevice({
    super.key,
    required this.device,
    this.isSelected = false,
  });

  @override
  ConsumerState createState() => _HomeScreenDeviceState();
}

class _HomeScreenDeviceState extends ConsumerState<HomeScreenDevice> {
  bool on = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      on = widget.device.device.isConnected;
    });
    print(widget.device.device.remoteId.str);
  }

  @override
  Widget build(BuildContext context) {
    final threshold = ref.watch(
      deviceThresholdProvider(widget.device.device.remoteId.str),
    );
    return InkWell(
      onTap: () {
        ref
            .read(selectedDeviceProvider.notifier)
            .setSelectedDevice(widget.device.device.remoteId.str);
      },
      child: Container(
        width: double.maxFinite,
        // height: 74,
        padding: const EdgeInsets.all(14),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color:
              widget.isSelected
                  ? ColorManager.selectedContainerBackground
                  : ColorManager.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color:
                  widget.isSelected
                      ? ColorManager.selectedContainerBorder
                      : ColorManager.containerBorder,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    Text(
                      widget.device.device.platformName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: ColorManager.primaryText,
                      ),
                    ),
                    if (widget.isSelected)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 4,
                        children: [
                          BLEPill(color: Colors.green),
                          Text(
                            "Current",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: ColorManager.secondaryText,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 4,
                  children: [
                    Text(
                      widget.device!.getBattery.data.toString() + "%",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: ColorManager.tertiaryText,
                      ),
                    ),
                    BLEPill(),
                    Text(
                      on ? "Connected" : "Disconnected",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: ColorManager.tertiaryText,
                      ),
                    ),
                    BLEPill(),
                    Text(
                      "$threshold DB",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: ColorManager.tertiaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            BLEToggle(
              value: on,
              onChanged: (value) async {
                print("onToggle: $value");
                await ref
                    .read(connectedDevicesProvider.notifier)
                    .connect(widget.device.device, shouldConnect: value);
                setState(() {
                  on = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
