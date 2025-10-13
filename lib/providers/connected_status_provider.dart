import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'connected_status_provider.g.dart';

@riverpod
class ConnectedStatus extends _$ConnectedStatus {
  @override
  bool build(String? id) => ref
          .read(connectedDevicesTrackerProvider.notifier)
          .isDeviceConnected(id);

  void toggle(bool isConnected) => state = isConnected;
}
