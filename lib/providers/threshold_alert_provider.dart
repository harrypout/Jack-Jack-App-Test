import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/models/notification_sf.dart';
import 'package:jackjack/providers/notifications_provider.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/screens/settings/settings_screen.dart';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'threshold_alert_provider.g.dart';

@Riverpod(keepAlive: true)
class ThresholdAlert extends _$ThresholdAlert {
  final Map<String, StreamSubscription> _subscriptions = {};
  DateTime? lastAlertTime;

  @override
  void build() {
    // Listen to threshold alerts from background service
    _listenToBackgroundAlerts();

    ref.onDispose(() {
      _cancelAllSubscriptions();
    });
  }

  /// Subscribe to alerts from background service
  void _listenToBackgroundAlerts() {
    FlutterBackgroundService().on('thresholdAlert').listen((event) {
      if (event != null) {
        final threshold = event['threshold'] as int;
        final deviceName = event['deviceName'] as String;

        debugPrint('📢 Received threshold alert from background: $deviceName - $threshold');

        // Add to notification list
        ref.read(notificationsProvider.notifier).addNotification(
              NotificationSF(device: deviceName, value: threshold),
            );
      }
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

    final deviceConnection = ref.read(connectedDevicesProvider)[deviceId];
    if (deviceConnection == null) {
      debugPrint("⚠️ Device $deviceId not in connected devices, skipping alert setup");
      return;
    }

    var deviceThresholdAlert = deviceConnection.thresholdAlert;

    if (deviceThresholdAlert.data == null ||
        deviceThresholdAlert.qualifiedCharacteristic == null) {
      debugPrint("⚠️ Threshold alert data not ready for $deviceId, retrying in 200ms");

      // Retry after a delay
      Future.delayed(const Duration(milliseconds: 200), () {
        setupDeviceAlert(deviceId);
      });
      return;
    }

    // Normal alert setup continues...
    final subscription = (deviceThresholdAlert.data as Stream<int>)
        .asBroadcastStream()
        .listen((value) {
          if (lastAlertTime == null ||
              DateTime.now().difference(lastAlertTime!) >=
                  notificationTimeout) {
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
    debugPrint("✅ Alert subscription active for $deviceId");
  }
}
