import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'connected_status_provider.g.dart';

@riverpod
class ConnectedStatus extends _$ConnectedStatus {
  @override
  bool build(String? id) {
    // Watch the tracker instead of reading once - makes provider reactive
    final connectedDevices = ref.watch(connectedDevicesTrackerProvider);
    return connectedDevices.value?.contains(id) ?? false;
  }

  // toggle() method removed - UI will auto-update when tracker changes
}
