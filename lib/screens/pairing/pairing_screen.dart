import 'package:jackjack/screens/pairing/pods/available_devices.dart';
import 'package:jackjack/services/app_initializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:jackjack/screens/pairing/widgets/bluetooth_device.dart';
import 'package:jackjack/screens/pairing/widgets/device_section.dart';
import 'package:jackjack/screens/pairing/widgets/scanner.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/connected_devices_provider.dart';

class PairingScreen extends ConsumerWidget {
  static const String id = 'pairing_screen';
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleDevices = ref.watch(deviceManagerProvider);
    final bleStatus = ref.watch(bleStatusNotifierProvider);
    final btOff = bleStatus != BleStatus.ready;

    debugPrint("Available devices: ${bleDevices.available.length}");
    for (var device in bleDevices.available) {
      debugPrint(" - ${device.name} (${device.id})");
    }
    debugPrint("Paired devices: ${bleDevices.paired.length}");
    for (var device in bleDevices.paired) {
      debugPrint(" - ${device.name} (${device.id})");
    }

    return Scaffold(
      body: BLEBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ThemeManager.horizontalPadding,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Connect Device", style: ThemeManager.displayTitle),
                      TextButton(
                        onPressed: btOff
                            ? null
                            : () {
                                ref.read(deviceManagerProvider.notifier).refreshScan();
                              },
                        child: Text(
                          "Refresh",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: btOff ? ColorManager.tertiaryText : ColorManager.accent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Scanner(
                    asset: "bluetooth-search",
                    animate: false,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Text(
                          btOff ? 'Bluetooth is turned off' : 'Scan Complete',
                          style: ThemeManager.displaySub,
                        ),
                        if (btOff) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Turn on Bluetooth to scan for and connect to devices',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: ColorManager.tertiaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (!btOff) ...[

                    // Paired Devices Section
                    if (bleDevices.paired.isNotEmpty)
                      DeviceSection(
                        title: "Paired Devices",
                        children: [
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: bleDevices.paired.length,
                            itemBuilder: (context, index) {
                              final device = bleDevices.paired[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: BluetoothDeviceWidget(
                                  device: device,
                                  isPaired: true,
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                    // Available Devices Section
                    if (bleDevices.available.isNotEmpty)
                      DeviceSection(
                        title: "Available Devices",
                        children: [
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: bleDevices.available.length,
                            itemBuilder: (context, index) {
                              final device = bleDevices.available[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: BluetoothDeviceWidget(
                                  device: device,
                                  isPaired: false,
                                  onConnect: (device) async {
                                    await ref
                                        .read(connectedDevicesProvider.notifier)
                                        .connect(device);
                                    ref.read(deviceManagerProvider.notifier).updateDeviceStreams();
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
