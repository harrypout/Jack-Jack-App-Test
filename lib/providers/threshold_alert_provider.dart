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
  DateTime? lastAlertTime;

  @override
  void build() {
    ref.onDispose(() {
      _cancelAllSubscriptions();
    });
  }

  void _cancelAllSubscriptions() {
    debugPrint("Canceling all threshold alert notifications");
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
      setupDeviceAlert(entry.key);
    }
  }

  void setupDeviceAlert(String deviceId) {
    debugPrint("creating alert for $deviceId");
    if (_subscriptions.containsKey(deviceId)) {
      debugPrint("cancelling existing subscription for $deviceId");
      _subscriptions[deviceId]?.cancel();
      _subscriptions.remove(deviceId);
    }
    var deviceThresholdAlert =
        ref.read(connectedDevicesProvider)[deviceId]!.thresholdAlert;

    if (deviceThresholdAlert.data != null &&
        deviceThresholdAlert.qualifiedCharacteristic != null) {
      final subscription = (deviceThresholdAlert.data as Stream<int>)
          .asBroadcastStream()
          .listen((value) {
        if(lastAlertTime == null || DateTime.now().difference(lastAlertTime!) >= Duration(seconds: 3)) {
              if (value > 0) {
                var device = ref.read(connectedDevicesProvider)[deviceId]!;
                if (device.getThreshold.data > 0) {
                  debugPrint(
                    "value: $value, device.getThreshold.data: ${device.getThreshold.data}",
                  );
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
              }
              lastAlertTime = DateTime.now();
            }
          });
      _subscriptions[deviceId] = subscription;
    }
  }
}
