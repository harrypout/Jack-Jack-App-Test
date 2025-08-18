import 'package:flutter/material.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_device_provider.g.dart';

@riverpod
class SelectedDevice extends _$SelectedDevice {
  @override
  String? build() => null;
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
