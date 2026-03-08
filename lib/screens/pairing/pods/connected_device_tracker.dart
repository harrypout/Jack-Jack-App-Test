import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/screens/pairing/pods/available_devices.dart';
import 'package:jackjack/services/app_lifecycle_manager.dart';
import 'package:jackjack/services/background_service_manager.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:jackjack/main.dart';

part 'connected_device_tracker.g.dart';

@Riverpod(keepAlive: true)
class ConnectedDevicesTracker extends _$ConnectedDevicesTracker {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final Set<String> _connectedDeviceIds = {};
  StreamSubscription? _connectionSubscription;
  final Map<String, StreamSubscription> _deviceConnections = {};

  @override
  FutureOr<Set<String>> build() {
    debugPrint("Building connected devices tracker...");
    _initialize();

    ref.onDispose(() {
      _connectionSubscription?.cancel();
      for (final subscription in _deviceConnections.values) {
        subscription.cancel();
      }
    });

    return _connectedDeviceIds;
  }

  Future<void> _initialize() async {
    debugPrint("Initializing connected devices tracker...");
    _connectionSubscription = _ble.connectedDeviceStream.listen((connectionStateUpdate) async {
      debugPrint("-----------------------------------------------------------------------$connectionStateUpdate");
      if (connectionStateUpdate.connectionState == DeviceConnectionState.connected) {
        // Skip if user manually disconnected this device
        final userDisconnected = prefs.getBool("user_disconnected_${connectionStateUpdate.deviceId}") ?? false;
        if (userDisconnected) {
          debugPrint('⏭️ Tracker: Ignoring connect for ${connectionStateUpdate.deviceId} (user manually disconnected)');
          return;
        }

        // On cold start (no GATT state), the OS may report stale connections
        // from a previous session. If no background service is maintaining them,
        // skip tracking so the device resumes advertising and the scan can
        // find it naturally for auto-connect.
        final isColdStart = ref.read(connectedDevicesProvider).isEmpty;
        if (isColdStart) {
          final bgRunning = await BackgroundServiceManager.isServiceRunning();
          if (!bgRunning) {
            debugPrint('⏭️ Tracker: Ignoring stale connection for ${connectionStateUpdate.deviceId} (cold start, no background service)');
            return;
          }
        }

        debugPrint('Connected to device: ${connectionStateUpdate.deviceId}');
        _connectedDeviceIds.add(connectionStateUpdate.deviceId);

        // Skip notifications and connection management when in background
        // — the background service handles these. Creating a connectToDevice
        // here would race with the background's connection.
        if (AppLifecycleManager.isInBackground) {
          debugPrint('⏭️ Tracker: Skipping connect handling for ${connectionStateUpdate.deviceId} (app in background)');
          state = AsyncData(Set<String>.from(_connectedDeviceIds));
          return;
        }

        // Show connection notification
        final connectedDevice = ref.read(connectedDevicesProvider)[connectionStateUpdate.deviceId];
        if (connectedDevice != null) {
          NotificationManager.instance.showConnectionAlert(
            deviceId: connectedDevice.device.id,
            deviceName: connectedDevice.device.name,
          );
        }

        if (!_deviceConnections.containsKey(connectionStateUpdate.deviceId)) {
          final deviceId = connectionStateUpdate.deviceId;
          final subscription = _ble.connectToDevice(
            id: deviceId,
            connectionTimeout: const Duration(seconds: 5),
          ).listen((update) {
            if (update.connectionState == DeviceConnectionState.disconnected) {
              if (AppLifecycleManager.isInBackground) return;
              _connectedDeviceIds.remove(deviceId);
              state = AsyncData(Set<String>.from(_connectedDeviceIds));
            }
          });

          _deviceConnections[deviceId] = subscription;
          // Subscription remains active to monitor connection state
        }
      } else if (connectionStateUpdate.connectionState == DeviceConnectionState.disconnected ||
                 connectionStateUpdate.connectionState == DeviceConnectionState.disconnecting) {
        // Skip disconnect handling when app is in background — the background
        // service is taking over the BLE connection and the foreground sees a
        // spurious disconnect during the handoff.
        if (AppLifecycleManager.isInBackground) {
          debugPrint('⏭️  Tracker: Ignoring disconnect for ${connectionStateUpdate.deviceId} (app in background)');
          return;
        }
        if(_connectedDeviceIds.contains(connectionStateUpdate.deviceId))
        {
          final disconnectedDevice = ref.read(
              connectedDevicesProvider)[connectionStateUpdate.deviceId];
          NotificationManager.instance.showDisconnectionAlert(
            deviceId: disconnectedDevice!.device.id,
            deviceName: disconnectedDevice.device.name,
          );
        }
        // UI will auto-update via reactive provider - no manual toggle needed
        _connectedDeviceIds.remove(connectionStateUpdate.deviceId);
      }
      state = AsyncData(Set<String>.from(_connectedDeviceIds));
    });

    ref.read(deviceManagerProvider);
  }

  bool isDeviceConnected(String? deviceId) {
    return _connectedDeviceIds.contains(deviceId);
  }

  Set<String> get connectedDevices => _connectedDeviceIds;

  void storeConnectionSubscription(
    String deviceId,
    StreamSubscription subscription,
  ) {
    _deviceConnections[deviceId]?.cancel();
    _deviceConnections[deviceId] = subscription;
  }

  /// Release all BLE subscriptions without clearing the connected device IDs.
  /// Used during background transition to avoid GATT races — the background
  /// service will create its own connections.
  void releaseAllSubscriptions() {
    debugPrint('🔌 Tracker: Releasing all BLE subscriptions for background handoff');
    for (final subscription in _deviceConnections.values) {
      subscription.cancel();
    }
    _deviceConnections.clear();
  }

  /// Mark a device as disconnected (used during state sync from background).
  void markDisconnected(String deviceId) {
    if (_connectedDeviceIds.contains(deviceId)) {
      _connectedDeviceIds.remove(deviceId);
      state = AsyncData(Set<String>.from(_connectedDeviceIds));
    }
  }

  Future<void> disconnectDevice(String deviceId) async {
    // Show disconnect notification before removing
    if (_connectedDeviceIds.contains(deviceId)) {
      final disconnectedDevice = ref.read(connectedDevicesProvider)[deviceId];
      if (disconnectedDevice != null) {
        NotificationManager.instance.showDisconnectionAlert(
          deviceId: disconnectedDevice.device.id,
          deviceName: disconnectedDevice.device.name,
        );
      }
    }

    _deviceConnections[deviceId]?.cancel();
    _deviceConnections.remove(deviceId);
    if (_connectedDeviceIds.contains(deviceId)) {
      _connectedDeviceIds.remove(deviceId);
      state = AsyncData(Set<String>.from(_connectedDeviceIds));
    }
  }
}
