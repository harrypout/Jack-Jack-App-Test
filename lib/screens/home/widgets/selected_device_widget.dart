import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/providers/connected_status_provider.dart';
import 'package:jackjack/providers/device_threshold_provider.dart';
import 'package:jackjack/widgets/ble_gauge.dart';
import 'package:jackjack/widgets/ble_indicator_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedDeviceHomeWidget extends ConsumerWidget {
  final BLEDevice? device;
  const SelectedDeviceHomeWidget({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(connectedStatusProvider(device?.device.id));
    final threshold = ref.watch(
      deviceThresholdProvider(device?.device.id ?? ""),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BLEGauge(
          selectedDevice: device?.device.name ?? "No Device Selected",
          valueStream: device?.getSoundLevel.data,
          //todo:test
          selectedValue: threshold ?? 0,
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
