import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
part 'periodic_task_provider.g.dart';

@Riverpod(keepAlive: true)
class PeriodicTaskService extends _$PeriodicTaskService {
  Timer? _periodicTimer;
  @override
  void build() {
    resumeForegroundPolling();
    ref.onDispose(stopPeriodicTask);
  }

  void stopPeriodicTask() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void resumeForegroundPolling() {
    stopPeriodicTask();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      for (final id in ref.read(connectedDevicesProvider).keys) {
        unawaited(
          ref.read(connectedDevicesProvider.notifier).refreshBattery(id),
        );
      }
    });
  }
}
