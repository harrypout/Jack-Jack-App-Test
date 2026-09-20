import 'package:jackjack/utils/device_display_name.dart';
import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/providers/last_recorded_alert_provider.dart';
import 'package:jackjack/providers/connected_status_provider.dart';
import 'package:jackjack/providers/device_threshold_provider.dart';
import 'package:jackjack/services/device_name_manager.dart';
import 'package:jackjack/utils/status_colors.dart';
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
    final deviceNames = ref.watch(deviceNamesProvider);
    final soundData = device?.getSoundLevel.data;
    final deviceId = device?.device.id;
    final lastAlert =
        deviceId == null
            ? null
            : ref.watch(lastRecordedAlertProvider(deviceId));
    final displayName = displayDeviceName(
      deviceNames[device?.device.id ?? ""] ??
          device?.device.name ??
          "No Device Connected",
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BLEGauge(
          deviceId: deviceId,
          selectedDevice: displayName,
          valueStream:
              isConnected && soundData is Stream<int> ? soundData : null,
          selectedValue: threshold,
          lastAlertAt: lastAlert,
        ),
        Row(
          spacing: 16,
          children: [
            IndicatorBox(
              title: "Battery",
              subtitle:
                  device?.getBattery.data is int
                      ? '${device!.getBattery.data}%'
                      : 'Unknown',
              asset: "battery",
              valueColor: batteryValueColor(
                int.tryParse("${device?.getBattery.data}"),
              ),
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
