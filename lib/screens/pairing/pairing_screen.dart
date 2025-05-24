import 'package:ble/screens/pairing/pods/available_devices.dart';
import 'package:flutter/material.dart';
import 'package:ble/screens/pairing/widgets/bluetooth_device.dart';
import 'package:ble/screens/pairing/widgets/device_section.dart';
import 'package:ble/screens/pairing/widgets/scanner.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:ble/widgets/ble_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/connected_devices_provider.dart';

class PairingScreen extends ConsumerWidget {
  static const String id = 'pairing_screen';
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleDevices = ref.watch(deviceManagerProvider);
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
                      Text(
                        "Connect Device",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: ColorManager.primaryText,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(deviceManagerProvider.notifier).refreshScan();
                        },
                        child: Text(
                          "Refresh",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: ColorManager.accent,
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
                    child: Text(
                      'Scan Complete',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: ColorManager.primaryText,
                      ),
                    ),
                  ),

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
