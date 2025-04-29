import 'package:ble/screens/pairing/pods/available_devices.dart';
import 'package:ble/screens/pairing/pods/paired_devices.dart';
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
    final availableDevicesPod = ref.watch(availableDevicesProvider);
    final pairedDevicesPod = ref.watch(pairedDevicesProvider);
    return Scaffold(
      body: BLEBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ThemeManager.horizontalPadding,
            ),
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
                    // if(ref.watch(connectedDevicesProvider).isNotEmpty)
                    // StreamBuilder<int>(
                    //   stream: ref.read(connectedDevicesProvider)[ref.read(connectedDevicesProvider).keys.first]?.soundStream,
                    //   builder: (context, snapshot) {
                    //     if (!snapshot.hasData) {
                    //       return const Text('Waiting for data...');
                    //     }
                    //
                    //     final soundLevel = snapshot.data!;
                    //     return Text('Sound Level: $soundLevel dB');
                    //   },
                    // ),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(availableDevicesProvider);
                        ref.invalidate(pairedDevicesProvider);
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
                Scanner(asset: "bluetooth-search"),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    availableDevicesPod.when(
                          data: (dat) => false,
                          error: (error, stackTrace) => false,
                          loading: () => true,
                        )
                        ? 'Searching for Device...'
                        : 'Scan Complete',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: ColorManager.primaryText,
                    ),
                  ),
                ),
                pairedDevicesPod.when(
                  error: (error, stackTrace) => Container(),
                  loading: () => CircularProgressIndicator(),
                  data:
                      (pairedDevices) => DeviceSection(
                        title: "Paired Devices",
                        children:
                            pairedDevices.map((device) {
                              return BluetoothDeviceWidget(
                                device: device,
                                isPaired: true,
                              );
                            }).toList(),
                      ),
                ),
                availableDevicesPod.when(
                  error: (error, stackTrace) => Container(),
                  loading: () => CircularProgressIndicator(),
                  data:
                      (availableDevices) => DeviceSection(
                        title: "Available Devices",
                        children:
                            availableDevices.map((scanResult) {
                              return BluetoothDeviceWidget(
                                device: scanResult.device,
                                isPaired: false,
                                onConnect: (device) async {
                                  await ref
                                      .read(connectedDevicesProvider.notifier)
                                      .connect(device);
                                  ref.invalidate(availableDevicesProvider);
                                  ref.invalidate(pairedDevicesProvider);
                                },
                              );
                            }).toList(),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
