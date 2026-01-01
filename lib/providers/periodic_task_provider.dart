import 'dart:async';
import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/main.dart';

part 'periodic_task_provider.g.dart';

@Riverpod(keepAlive: true)
class PeriodicTaskService extends _$PeriodicTaskService {
  Timer? _periodicTimer;

  @override
  void build() {
    stopPeriodicTask();

    // Only start foreground polling if background service is NOT active
    final backgroundActive = prefs.getBool("backgroundMonitoring") ?? false;
    if (!backgroundActive) {
      _startForegroundPolling();
    }

    ref.onDispose(() {
      stopPeriodicTask();
    });
  }

  /// Start battery polling in foreground
  void _startForegroundPolling() {
    _periodicTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final connectedDevices = ref.read(connectedDevicesProvider);
      final connectedDeviceTracker =
          ref.read(connectedDevicesTrackerProvider.notifier).connectedDevices;
      connectedDevices.keys
          .where((id) => connectedDeviceTracker.contains(id))
          .map((id) => connectedDevices[id]?.getBattery.getValue());
    });
  }

  void stopPeriodicTask() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Resume foreground polling (called when background service stops)
  void resumeForegroundPolling() {
    stopPeriodicTask();
    _startForegroundPolling();
  }
}
