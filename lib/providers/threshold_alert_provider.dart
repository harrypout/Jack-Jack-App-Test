import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/models/notification_sf.dart';
import 'package:jackjack/providers/notifications_provider.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'threshold_alert_provider.g.dart';

@Riverpod(keepAlive: true)
class ThresholdAlert extends _$ThresholdAlert {
  final Map<String, StreamSubscription> _subscriptions = {};

  @override
  void build() {
    ref.onDispose(() {
      _cancelAllSubscriptions();
    });
  }

  void _cancelAllSubscriptions() {
    for (var subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  void setupAlerts() {
    Map<String, BLEDevice> devices = ref.read(connectedDevicesProvider);

    List<String> deviceIdsToRemove = [];
    for (String deviceId in _subscriptions.keys) {
      if (!devices.containsKey(deviceId)) {
        _subscriptions[deviceId]?.cancel();
        deviceIdsToRemove.add(deviceId);
      }
    }

    for (String deviceId in deviceIdsToRemove) {
      _subscriptions.remove(deviceId);
    }
    for (var entry in devices.entries) {
      setupDeviceAlert(entry.key, entry.value);
    }
  }

  void setupDeviceAlert(String deviceId, BLEDevice device) {
    debugPrint("creating alert for $deviceId");
    if (_subscriptions.containsKey(deviceId)) {
      _subscriptions[deviceId]?.cancel();
      _subscriptions.remove(deviceId);
    }

    if (device.thresholdAlert.data != null &&
        device.thresholdAlert.qualifiedCharacteristic != null) {
      final subscription = (device.thresholdAlert.data as Stream<int>)
          .asBroadcastStream()
          .listen((value) {
            debugPrint("value: $value, device.getThreshold.data: ${device.getThreshold.data}");
            if (value > 0 && device.getThreshold.data> 0) {
              final deviceName = device.device.name;
              NotificationManager.instance.showThresholdAlert(
                deviceId: deviceId,
                deviceName: deviceName,
                threshold: value,
              );
              ref
                  .read(notificationsProvider.notifier)
                  .addNotification(
                    NotificationSF(device: deviceName, value: value),
                  );
            }
          });
      _subscriptions[deviceId] = subscription;
    }
  }
}
