import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'connected_device_tracker.g.dart';

/// Presentation of sessions that completed GATT setup. Connection ownership is
/// exclusively in DeviceConnection; observing this provider never connects.
@Riverpod(keepAlive: true)
class ConnectedDevicesTracker extends _$ConnectedDevicesTracker {
  @override
  FutureOr<Set<String>> build() => <String>{};
  Set<String> get connectedDevices => state.valueOrNull ?? <String>{};
  bool isDeviceConnected(String? id) => connectedDevices.contains(id);
  void markConnected(String id) => state = AsyncData({...connectedDevices, id});
  void markDisconnected(String id) =>
      state = AsyncData({...connectedDevices}..remove(id));
}
