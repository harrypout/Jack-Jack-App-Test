import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:jackjack/widgets/ble_gauge.dart';
import 'package:jackjack/widgets/ble_indicator_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedDeviceHomeWidget extends ConsumerWidget {
  final BLEDevice? device;
  const SelectedDeviceHomeWidget({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref
        .watch(connectedDevicesTrackerProvider.notifier)
        .isDeviceConnected(device?.device.id);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BLEGauge(
          selectedDevice: device?.device.name ?? "No Device Selected",
          valueStream: device?.getSoundLevel.data,
        ),
        Row(
          spacing: 16,
          children: [
            IndicatorBox(
              title: "Battery",
              subtitle: "${device?.getBattery.data ?? "0"} %",
              asset: "battery",
            ),
            IndicatorBox(
              title: "Status",
              subtitle: isConnected ? "Connected" : "Disconnected",
              asset: "status",
            ),
          ],
        ),
      ],
    );
  }
}
