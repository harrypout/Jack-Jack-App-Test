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

  // Cooldown per device. A single shared timestamp meant one loud device
  // suppressed threshold alerts for every other connected device.
  final Map<String, DateTime> _lastAlertTimes = {};

  bool _inCooldown(String deviceId) {
    final last = _lastAlertTimes[deviceId];
    return last != null &&
        DateTime.now().difference(last) < notificationTimeout;
  }

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

        if (threshold > 0) {
          final deviceId = event['deviceId'] as String;

          // Apply same per-device cooldown as foreground alerts
          if (_inCooldown(deviceId)) {
            return;
          }

          // Show OS notification
          NotificationManager.instance.showThresholdAlert(
            deviceId: deviceId,
            deviceName: deviceName,
            threshold: threshold,
          );

          // Add to in-app notification list
          ref.read(notificationsProvider.notifier).addNotification(
                NotificationSF(device: deviceName, value: threshold),
              );

          _lastAlertTimes[deviceId] = DateTime.now();
        }
      }
    });

    FlutterBackgroundService().on('deviceDisconnected').listen((event) {
      if (event != null) {
        final deviceId = event['deviceId'] as String;
        final deviceName = event['deviceName'] as String? ?? 'Unknown Device';
        debugPrint('📱 Background disconnect notification for $deviceName ($deviceId)');
        NotificationManager.instance.showDisconnectionAlert(
          deviceId: deviceId,
          deviceName: deviceName,
        );
      }
    });

    FlutterBackgroundService().on('deviceConnected').listen((event) {
      if (event != null) {
        final deviceId = event['deviceId'] as String;
        final deviceName = event['deviceName'] as String? ?? 'Unknown Device';
        debugPrint('📱 Background connect notification for $deviceName ($deviceId)');
        NotificationManager.instance.showConnectionAlert(
          deviceId: deviceId,
          deviceName: deviceName,
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
          // Per-device cooldown, advanced only when an alert actually fires —
          // previously the shared timestamp advanced even on value == 0
          // events, which could indefinitely postpone real alerts.
          if (_inCooldown(deviceId)) {
            return;
          }
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
              _lastAlertTimes[deviceId] = DateTime.now();
            }
          }
        });

    _subscriptions[deviceId] = subscription;
    debugPrint("✅ Alert subscription active for $deviceId");
  }
}
