import 'package:ble/providers/paired_devices.dart';
import 'package:ble/utils/env_manager.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'available_devices.g.dart';

@riverpod
Stream<List<ScanResult>> availableDevices(Ref ref) {
  print("Available");
  FlutterBluePlus.startScan(
    timeout: const Duration(seconds: 10),
    withServices: [
      Guid(configs.setThresholdUUIDS.service),
      // ...configs.uuids.map((uuid)=> Guid(uuid.service))
    ],
  );
  Stream<List<ScanResult>> results = FlutterBluePlus.scanResults.map(
    (deviceList) => deviceList.where(
      (scanResult) => !PairedDevicesUUID.list.contains(scanResult.device.remoteId.str)
    ).toList()
  );

  print("Available Devices");
  results.forEach((device){
    print(device);
  });
  print("Scanning");

  return results;
}
