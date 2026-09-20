import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'selected_device_provider.g.dart';

@Riverpod(keepAlive: true)
class SelectedDevice extends _$SelectedDevice {
  Future<void> _pending = Future.value();
  bool _disposed = false;
  int _revision = 0;
  @override
  String? build() {
    ref.onDispose(() {
      _disposed = true;
    });
    ref.listen(connectedDevicesProvider, (previous, next) {
      if (state != null && next.containsKey(state)) {
        final selected = next[state]!;
        if (!identical(previous?[state], selected) &&
            selected.setSoundLevel.qualifiedCharacteristic != null) {
          unawaited(
            selected.setSoundLevel.setValue(1).catchError((Object error) {
              debugPrint('Meter enable failed: $error');
            }),
          );
        }
        return;
      }
      unawaited(setSelectedDevice(next.isEmpty ? null : next.keys.first));
    });
    return null;
  }

  Future<void> setSelectedDevice(String? id) {
    final revision = ++_revision;
    final operation = _pending.then((_) async {
      if (_disposed || revision != _revision) return;
      final devices = ref.read(connectedDevicesProvider);
      if (id != null && !devices.containsKey(id)) {
        throw StateError('Device is no longer available');
      }
      final previous = devices[state];
      final next = devices[id];
      if (state == id) return;
      try {
        await previous?.setSoundLevel.setValue(0);
      } catch (error) {
        debugPrint('Previous meter stream unavailable: $error');
      }
      // Publish selection before any read completes. The meter resets to unknown
      // immediately and binds the selected device's existing session stream.
      if (_disposed || revision != _revision) return;
      state = id;
      try {
        await next?.setSoundLevel.setValue(1);
      } catch (error) {
        debugPrint('Selected meter stream unavailable: $error');
      }
    });
    _pending = operation.catchError((Object error) {
      debugPrint('$error');
    });
    return operation;
  }
}
