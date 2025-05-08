import 'package:ble/screens/pairing/pods/available_devices.dart';
import 'package:ble/screens/pairing/pods/paired_devices.dart';
import 'package:flutter/material.dart';
import 'package:ble/screens/pairing/widgets/bluetooth_device.dart';
import 'package:ble/screens/pairing/widgets/device_section.dart';
import 'package:ble/screens/pairing/widgets/scanner.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:ble/widgets/ble_background.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
                          ref.read(availableDevicesProvider.notifier).refresh();
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
                  Scanner(
                    asset: "bluetooth-search",
                    animate: availableDevicesPod.when(
                      data: (dat) => false,
                      error: (error, stackTrace) => false,
                      loading: () => true,
                    ),
                  ),
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
                    loading:
                        () => DeviceSection(
                          title: "Paired Devices",
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Skeletonizer(
                                child: BluetoothDeviceWidget(
                                  device: BluetoothDevice(
                                    remoteId: DeviceIdentifier(
                                      "00:00:00:00:00:00",
                                    ),
                                  ),
                                  isPaired: true,
                                  loader: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                    data:
                        (pairedDevices) =>
                            pairedDevices.isEmpty
                                ? Container()
                                : DeviceSection(
                                  title: "Paired Devices",
                                  children: [
                                    ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: pairedDevices.length,
                                      itemBuilder: (context, index) {
                                        final device = pairedDevices[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: BluetoothDeviceWidget(
                                            device: device,
                                            isPaired: true,
                                          ),
                                        );
                                      },
                                    ),
                                    // ...pairedDevices
                                    //    .map(
                                    //      (device) => Padding(
                                    //        padding: const EdgeInsets.only(bottom: 8),
                                    //        child: BluetoothDeviceWidget(
                                    //          device: device,
                                    //          isPaired: true,
                                    //        ),
                                    //      ),
                                    //    )
                                    //    .toList(),
                                  ],
                                ),
                  ),
                  availableDevicesPod.when(
                    error: (error, stackTrace) => Container(),
                    loading:
                        () => DeviceSection(
                          title: "Available Devices",
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Skeletonizer(
                                child: BluetoothDeviceWidget(
                                  device: BluetoothDevice(
                                    remoteId: DeviceIdentifier(
                                      "00:00:00:00:00:00",
                                    ),
                                  ),
                                  isPaired: false,
                                  loader: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                    data:
                        (availableDevices) =>
                            availableDevices.isEmpty
                                ? Container()
                                : DeviceSection(
                                  title: "Available Devices",
                                  children: [
                                    ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: availableDevices.length,
                                      itemBuilder: (context, index) {
                                        final scanResult =
                                            availableDevices[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: BluetoothDeviceWidget(
                                            device: scanResult.device,
                                            isPaired: false,
                                            onConnect: (device) async {
                                              await ref
                                                  .read(
                                                    connectedDevicesProvider
                                                        .notifier,
                                                  )
                                                  .connect(device);
                                              ref
                                                  .read(
                                                    availableDevicesProvider
                                                        .notifier,
                                                  )
                                                  .refresh();
                                              ref.invalidate(
                                                pairedDevicesProvider,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                    // ...availableDevices
                                    //                                   .map(
                                    //                                     (scanResult) => Padding(
                                    //                                       padding: const EdgeInsets.only(bottom: 8),
                                    //                                       child: BluetoothDeviceWidget(
                                    //                                         device: scanResult.device,
                                    //                                         isPaired: false,
                                    //                                         onConnect: (device) async {
                                    //                                           await ref
                                    //                                               .read(
                                    //                                                 connectedDevicesProvider.notifier,
                                    //                                               )
                                    //                                               .connect(device);
                                    //                                           ref
                                    //                                               .read(
                                    //                                                 availableDevicesProvider.notifier,
                                    //                                               )
                                    //                                               .refresh();
                                    //                                           ref.invalidate(pairedDevicesProvider);
                                    //                                         },
                                    //                                       ),
                                    //                                     ),
                                    //                                   )
                                    //                                   .toList(),
                                  ],
                                ),
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
