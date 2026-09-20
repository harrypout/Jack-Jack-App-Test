import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'device_threshold_provider.g.dart';

@riverpod
class DeviceThreshold extends _$DeviceThreshold {
  int? _confirmed;
  Future<void> _pending = Future.value();
  bool _disposed = false;
  int _revision = 0;

  @override
  int? build(String deviceID) {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });
    final value = ref.watch(
      connectedDevicesProvider.select(
        (devices) => devices[deviceID]?.getThreshold.data,
      ),
    );
    _confirmed = value is int ? value : null;
    return _confirmed;
  }

  void change(int threshold) {
    _revision++;
    state = threshold;
  }

  Future<void> saveToDevice(String deviceID, int threshold) {
    final revision = ++_revision;
    final device = ref.read(connectedDevicesProvider)[deviceID];
    final operation = _pending.then((_) async {
      try {
        if (threshold < 30 || threshold > 120) {
          throw RangeError.range(threshold, 30, 120);
        }
        if (device == null ||
            !identical(ref.read(connectedDevicesProvider)[deviceID], device)) {
          throw StateError('Device is no longer connected');
        }
        await device.setThreshold.setValue(threshold);
        await device.getThreshold.getValue();
        if (_disposed) return;
        if (!identical(ref.read(connectedDevicesProvider)[deviceID], device)) {
          throw StateError('Connection changed while saving');
        }
        final value = device.getThreshold.data;
        if (value is! int || value < 30 || value > 120) {
          throw StateError('Device returned an invalid threshold');
        }
        _confirmed = value;
        if (revision == _revision) state = value;
      } catch (_) {
        if (!_disposed && revision == _revision) state = _confirmed;
        rethrow;
      }
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}
