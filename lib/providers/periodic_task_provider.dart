import 'dart:async';
import 'package:ble/screens/pairing/pods/connected_device_tracker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ble/providers/connected_devices_provider.dart';

part 'periodic_task_provider.g.dart';

@Riverpod(keepAlive: true)
class PeriodicTaskService extends _$PeriodicTaskService {
  Timer? _periodicTimer;

  @override
  void build() {
    stopPeriodicTask();

    _periodicTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final connectedDevices = ref.read(connectedDevicesProvider);
      final connectedDeviceTracker =
          ref.read(connectedDevicesTrackerProvider.notifier).connectedDevices;
      connectedDevices.keys
          .where((id) => connectedDeviceTracker.contains(id))
          .map((id) => connectedDevices[id]?.getBattery.getValue());
    });

    ref.onDispose(() {
      stopPeriodicTask();
    });
  }

  void stopPeriodicTask() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}
