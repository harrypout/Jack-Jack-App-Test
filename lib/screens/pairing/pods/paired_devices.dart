import 'dart:io';

import 'package:ble/providers/paired_devices.dart';
import 'package:ble/providers/connected_devices_provider.dart';
import 'package:ble/utils/env_manager.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ble/main.dart';

part 'paired_devices.g.dart';

Future<bool> requestLocationAndNearbyDevicesPermissions() async {
  if (Platform.isAndroid) {
    // Request location permission
    PermissionStatus locationStatus = await Permission.location.request();

    // For Android 12+ we need BLUETOOTH_SCAN and BLUETOOTH_CONNECT permissions
    // which are used to discover and interact with nearby Bluetooth devices
    bool hasPermissions = locationStatus.isGranted;

    // Check Android version for nearby devices permissions (Bluetooth specific)
    if ((int.tryParse(Platform.version.split('.')[0]) ?? 0) >= 12) {
      Map<Permission, PermissionStatus> bluetoothStatuses =
          await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
          ].request();

      hasPermissions =
          hasPermissions &&
          bluetoothStatuses[Permission.bluetoothScan]!.isGranted &&
          bluetoothStatuses[Permission.bluetoothConnect]!.isGranted;
    }

    return hasPermissions;
  } else if (Platform.isIOS) {
    // iOS handles Bluetooth permissions through system dialogs
    return true;
  }
  return false;
}

@Riverpod(keepAlive: true)
Future<List<BluetoothDevice>> pairedDevices(Ref ref) async {
  print("Paired");
  if (await requestLocationAndNearbyDevicesPermissions()) {
    // ref.invalidate(connectedDevicesProvider);
    if (Platform.isAndroid) {
      List<BluetoothDevice> filteredDevices =
          (await FlutterBluePlus.bondedDevices)
              .where(
                (device) =>
                    PairedDevicesUUID.list.contains(device.remoteId.str),
              )
              .toList();
      print(ref.read(connectedDevicesProvider).keys);
      filteredDevices.forEach(
        (device) =>
            ref
                    .read(connectedDevicesProvider)
                    .keys
                    .contains(device.remoteId.str)
                ? null
                : ref
                    .read(connectedDevicesProvider.notifier)
                    .connect(
                      device,
                      shouldConnect: (prefs.getBool("autoConnect") ?? false),
                    ),
      );
      return filteredDevices;
    } else {
      return FlutterBluePlus.systemDevices([
        Guid(configs.setThresholdUUIDS.service),
        // ...configs.uuids.map((uuid)=> Guid(uuid.service))
      ]);
    }
  } else {
    return [];
  }
}
