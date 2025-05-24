// import 'dart:io';
// import 'package:ble/providers/connected_devices_provider.dart';
// import 'package:ble/utils/env_manager.dart';
// import 'package:ble/utils/permission_manager.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';
// import 'package:ble/main.dart';
//
// part 'paired_devices.g.dart';
//
// @Riverpod(keepAlive: true)
// Future<List<BluetoothDevice>> pairedDevices(Ref ref) async {
//   List<BluetoothDevice> pairedDevices = [];
//   debugPrint("Paired");
//   if (await PermissionManager.check()) {
//     pairedDevices =
//         Platform.isAndroid
//             ? await FlutterBluePlus.bondedDevices
//             : await FlutterBluePlus.systemDevices([
//               Guid(configs.setThresholdUUIDS.service),
//               // ...configs.uuids.map((uuid)=> Guid(uuid.service))
//             ]);
//     debugPrint(ref.read(connectedDevicesProvider).keys);
//     for (var device in pairedDevices) {
//       debugPrint(device);
//       ref.read(connectedDevicesProvider).keys.contains(device.remoteId.str)
//           ? null
//           : ref
//               .read(connectedDevicesProvider.notifier)
//               .connect(
//                 device,
//                 shouldConnect: (prefs.getBool("autoConnect") ?? false),
//               );
//     }
//   }
//   return pairedDevices;
// }
