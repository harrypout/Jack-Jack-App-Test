import 'package:flutter/material.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_device_provider.g.dart';

@Riverpod(keepAlive: true)
class SelectedDevice extends _$SelectedDevice {
  @override
  String? build() {
    ref.listen(connectedDevicesProvider, (previous, next) {
      // No device selected yet — auto-select the first connected device
      if (state == null && next.isNotEmpty) {
        setSelectedDevice(next.keys.first);
        return;
      }

      // If current selection is still connected, keep it
      if (state != null && next.containsKey(state)) return;

      // If current selection is disconnected but no other devices, keep it
      if (state != null && next.isEmpty) return;

      // If current selection is disconnected and others exist, pick the first
      if (state != null && next.isNotEmpty) {
        setSelectedDevice(next.keys.first);
      }
    });
    return null;
  }

  Future<void> setSelectedDevice(String? deviceId) async {
    try {
      if (state != null) {
        await ref
            .read(connectedDevicesProvider)[state]
            ?.setSoundLevel
            .setValue(0);
        await ref
            .read(connectedDevicesProvider)[state]
            ?.getSoundLevel
            .getValue();
      }
      await ref
          .read(connectedDevicesProvider)[deviceId]
          ?.setSoundLevel
          .setValue(1);
      await ref
          .read(connectedDevicesProvider)[deviceId]
          ?.getSoundLevel
          .getValue();
    } catch (e) {
      debugPrint(e.toString());
    }
    state = deviceId;
  }
}
