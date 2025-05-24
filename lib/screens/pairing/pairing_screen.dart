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

    // Debug lists
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
                          // Option 1: Invalidate the provider to restart scanning
                          // ref.invalidate(deviceManagerProvider);

                          // Option 2: Use the refreshScan method if available
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





// import 'dart:typed_data';
// import 'package:ble/screens/pairing/pods/available_devices.dart';
// import 'package:flutter/material.dart';
// import 'package:ble/screens/pairing/widgets/bluetooth_device.dart';
// import 'package:ble/screens/pairing/widgets/device_section.dart';
// import 'package:ble/screens/pairing/widgets/scanner.dart';
// import 'package:ble/utils/color_manager.dart';
// import 'package:ble/utils/theme_manager.dart';
// import 'package:ble/widgets/ble_background.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:skeletonizer/skeletonizer.dart';
//
// import '../../providers/connected_devices_provider.dart';
//
// class PairingScreen extends ConsumerWidget {
//   static const String id = 'pairing_screen';
//   const PairingScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final bleDevices = ref.watch(deviceManagerProvider);
//     // Debug streams
//     bleDevices.available.listen((devices) {
//       debugPrint("STREAM DEBUG - Available devices: ${devices.length}");
//       for (var device in devices) {
//         debugPrint(" - ${device.name} (${device.id})");
//       }
//     });
//
//     bleDevices.paired.listen((devices) {
//       debugPrint("STREAM DEBUG - Paired devices: ${devices.length}");
//       for (var device in devices) {
//         debugPrint(" - ${device.name} (${device.id})");
//       }
//     });
//
//     return Scaffold(
//       body: BLEBackground(
//         child: SafeArea(
//           child: Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: ThemeManager.horizontalPadding,
//             ),
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "Connect Device",
//                         style: TextStyle(
//                           fontWeight: FontWeight.w700,
//                           fontSize: 20,
//                           color: ColorManager.primaryText,
//                         ),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           ref.invalidate(deviceManagerProvider);
//                         },
//                         child: Text(
//                           "Refresh",
//                           style: TextStyle(
//                             fontWeight: FontWeight.w700,
//                             fontSize: 14,
//                             color: ColorManager.accent,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   Scanner(
//                     asset: "bluetooth-search",
//                     animate:
//                         false, // You could add a separate scanning state if needed
//                   ),
//                   Padding(
//                     padding: EdgeInsets.symmetric(vertical: 20),
//                     child: Text(
//                       'Scan Complete',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w700,
//                         fontSize: 18,
//                         color: ColorManager.primaryText,
//                       ),
//                     ),
//                   ),
//                   // Paired Devices Section
//                   StreamBuilder<List<DiscoveredDevice>>(
//                     stream: bleDevices.paired,
//                     builder: (context, snapshot) {
//                       debugPrint(
//                         "Stream state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, error: ${snapshot.error}",
//                       );
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return DeviceSection(
//                           title: "Paired Devices",
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.only(bottom: 8),
//                               child: Skeletonizer(
//                                 child: BluetoothDeviceWidget(
//                                   device: DiscoveredDevice(
//                                     id: "00:00:00:00:00:00",
//                                     name: "Device Name",
//                                     serviceData: {},
//                                     manufacturerData: Uint8List(0),
//                                     rssi: 0,
//                                     serviceUuids: [],
//                                   ),
//                                   isPaired: true,
//                                   loader: true,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         );
//                       }
//
//                       final pairedDevices = snapshot.data ?? [];
//
//                       if (pairedDevices.isEmpty) return Container();
//
//                       return DeviceSection(
//                         title: "Paired Devices",
//                         children: [
//                           ListView.builder(
//                             physics: const NeverScrollableScrollPhysics(),
//                             shrinkWrap: true,
//                             itemCount: pairedDevices.length,
//                             itemBuilder: (context, index) {
//                               final device = pairedDevices[index];
//                               return Padding(
//                                 padding: const EdgeInsets.only(bottom: 8),
//                                 child: BluetoothDeviceWidget(
//                                   device: device,
//                                   isPaired: true,
//                                 ),
//                               );
//                             },
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//
//                   // Available Devices Section
//                   StreamBuilder<List<DiscoveredDevice>>(
//                     stream: bleDevices.available,
//                     builder: (context, snapshot) {
//                       debugPrint(
//                         "Stream state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, error: ${snapshot.error}",
//                       );
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return DeviceSection(
//                           title: "Available Devices",
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.only(bottom: 8),
//                               child: Skeletonizer(
//                                 child: BluetoothDeviceWidget(
//                                   device: DiscoveredDevice(
//                                     id: "00:00:00:00:00:00",
//                                     name: "Device Name",
//                                     serviceData: {},
//                                     manufacturerData: Uint8List(0),
//                                     rssi: 0,
//                                     serviceUuids: [],
//                                   ),
//                                   isPaired: false,
//                                   loader: true,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         );
//                       }
//
//                       final availableDevices = snapshot.data ?? [];
//
//                       if (availableDevices.isEmpty) return Container();
//
//                       return DeviceSection(
//                         title: "Available Devices",
//                         children: [
//                           ListView.builder(
//                             physics: const NeverScrollableScrollPhysics(),
//                             shrinkWrap: true,
//                             itemCount: availableDevices.length,
//                             itemBuilder: (context, index) {
//                               final device = availableDevices[index];
//
//                               return Padding(
//                                 padding: const EdgeInsets.only(bottom: 8),
//                                 child: BluetoothDeviceWidget(
//                                   device: device,
//                                   isPaired: false,
//                                   onConnect: (device) async {
//                                     await ref
//                                         .read(connectedDevicesProvider.notifier)
//                                         .connect(device);
//                                     ref.invalidate(deviceManagerProvider);
//                                   },
//                                 ),
//                               );
//                             },
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                   SizedBox(height: 40),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
