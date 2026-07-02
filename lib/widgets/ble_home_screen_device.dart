import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/providers/connected_status_provider.dart';
import 'package:jackjack/providers/device_threshold_provider.dart';
import 'package:jackjack/providers/loading_provider.dart';
import 'package:jackjack/providers/selected_device_provider.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/services/device_name_manager.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/widgets/ble_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jackjack/widgets/ble_toggle_row.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../main.dart';

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
  bool sound = true;
  bool vibration = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      sound = prefs.getBool("${widget.device.device.id}s") ?? true;
      vibration = prefs.getBool("${widget.device.device.id}v") ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final threshold = ref.watch(
      deviceThresholdProvider(widget.device.device.id),
    );
    final isLoading = ref.watch(loadingProvider(widget.device.device.id));
    final isConnected = ref.watch(
      connectedStatusProvider(widget.device.device.id),
    );
    final deviceNames = ref.watch(deviceNamesProvider);
    final displayName =
        deviceNames[widget.device.device.id] ?? widget.device.device.name;

    return Skeletonizer(
      enabled: isLoading,
      child: ExpansionTile(
        title: Row(
          spacing: 12,
          children: [
            Text(
              displayName,
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
                  BLEPill(color: ColorManager.success),
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
        subtitle: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 6,
          children: [
            Text(
              "${widget.device.getBattery.data}%",
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: ColorManager.tertiaryText,
              ),
            ),
            BLEPill(),
            Text(
              isConnected ? "Connected" : "Disconnected",
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
        backgroundColor: ColorManager.white,
        collapsedBackgroundColor: ColorManager.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: ColorManager.containerBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        collapsedShape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: ColorManager.containerBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        childrenPadding: EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        expandedAlignment: Alignment.topLeft,
        children: [
          BleToggleRow(
            "Connect",
            value: isConnected,
            onChanged: (value) async {
              debugPrint("onToggle: $value");
              await ref
                  .read(connectedDevicesProvider.notifier)
                  .connect(widget.device.device, shouldConnect: value);
              if (value) {
                ref
                    .read(selectedDeviceProvider.notifier)
                    .setSelectedDevice(widget.device.device.id);
              }
              debugPrint("onToggle: $value");
            },
          ),
          // BleToggleRow(
          //   "Current Device",
          //   value: widget.isSelected,
          //   onChanged: (value) {
          //     ref
          //         .read(selectedDeviceProvider.notifier)
          //         .setSelectedDevice(widget.device.device.id);
          //   },
          // ),
          BleToggleRow(
            "Alerts",
            value: sound && vibration,
            onChanged: (value) {
              setState(() {
                sound = value;
                vibration = value;
              });
              prefs.setBool("${widget.device.device.id}s", value);
              prefs.setBool("${widget.device.device.id}v", value);
            },
          ),
          // BleToggleRow(
          //   "Sound Alert",
          //   value: sound,
          //   onChanged: (value) {
          //     setState(() {
          //       sound = value;
          //        vibration = value;
          //     });
          //     prefs.setBool("${widget.device.device.id}s", value);
          //   },
          // ),
          // BleToggleRow(
          //   "Vibration Alert",
          //   value: vibration,
          //   onChanged: (value) {
          //     setState(() {
          //       vibration = value;
          //     });
          //     prefs.setBool("${widget.device.device.id}v", value);
          //   },
          // ),
          if (!(threshold == null ||
              (threshold != null && (threshold < 30 || threshold > 120))))
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Set Sound Threshold ",
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: ColorManager.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${threshold?.toInt()} DB",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: ColorManager.tertiaryText,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: threshold!.toDouble(),
                  max: 120,
                  min: 30,
                  activeColor: ColorManager.accent,
                  onChanged: (val) {
                    ref
                        .read(
                          deviceThresholdProvider(
                            widget.device.device.id,
                          ).notifier,
                        )
                        .change(val.toInt());
                  },
                  onChangeEnd: (value) {
                    ref
                        .read(
                          deviceThresholdProvider(
                            widget.device.device.id,
                          ).notifier,
                        )
                        .saveToDevice(widget.device.device.id, value.toInt());
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
