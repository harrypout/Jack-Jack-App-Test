import 'package:ble/utils/env_manager.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'available_devices.g.dart';

@riverpod
class AvailableDevices extends _$AvailableDevices {
  @override
  Stream<List<ScanResult>> build() => FlutterBluePlus.scanResults;

  Future<void> refresh() async => await FlutterBluePlus.startScan(
    timeout: const Duration(seconds: 10),
    withServices: [
      Guid(configs.setThresholdUUIDS.service),
      // ...configs.uuids.map((uuid)=> Guid(uuid.service))
    ],
  );
}
