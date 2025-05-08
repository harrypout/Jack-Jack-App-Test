import 'package:ble/providers/connected_devices_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'device_threshold_provider.g.dart';

@riverpod
class DeviceThreshold extends _$DeviceThreshold {
  @override
  int? build(String deviceID) {
    final connectedDevices = ref.watch(connectedDevicesProvider);
    return connectedDevices[deviceID]?.getThreshold.data;
  }

  Future<void> saveToDevice(String deviceID, int threshold) async {
    final connectedDevices = ref.watch(connectedDevicesProvider);
    await connectedDevices[deviceID]?.setThreshold.setValue(threshold);
    await connectedDevices[deviceID]?.getThreshold.getValue();
    state = threshold;
  }
}
