import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/providers/connected_status_provider.dart';
import 'package:jackjack/screens/pairing/pods/available_devices.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:jackjack/utils/foreground_service_manager.dart';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
      ForegroundServiceManager.stop();
    });

    return _connectedDeviceIds;
  }

  Future<void> _initialize() async {
    debugPrint("Initializing connected devices tracker...");
    // Passive observer. The actual connection for each device is owned by
    // ConnectedDevices.connect() (stored via storeConnectionSubscription);
    // this stream only mirrors connection state and raises disconnect alerts.
    // Previously this opened a second connectToDevice per device and then
    // immediately disconnected it, which tore down freshly-made connections.
    _connectionSubscription = _ble.connectedDeviceStream.listen((
      connectionStateUpdate,
    ) {
      final deviceId = connectionStateUpdate.deviceId;
      debugPrint(
        "Connection update: $deviceId -> ${connectionStateUpdate.connectionState}",
      );

      switch (connectionStateUpdate.connectionState) {
        case DeviceConnectionState.connected:
          _connectedDeviceIds.add(deviceId);
          ref.read(connectedStatusProvider(deviceId).notifier).toggle(true);
          break;
        case DeviceConnectionState.disconnecting:
        case DeviceConnectionState.disconnected:
          if (_connectedDeviceIds.contains(deviceId)) {
            final disconnectedDevice =
                ref.read(connectedDevicesProvider)[deviceId];
            if (disconnectedDevice != null) {
              NotificationManager.instance.showDisconnectionAlert(
                deviceId: disconnectedDevice.device.id,
                deviceName: disconnectedDevice.device.name,
              );
            }
          }
          ref.read(connectedStatusProvider(deviceId).notifier).toggle(false);
          _connectedDeviceIds.remove(deviceId);
          // Release the owning connection subscription for this device.
          _deviceConnections[deviceId]?.cancel();
          _deviceConnections.remove(deviceId);
          break;
        case DeviceConnectionState.connecting:
          break;
      }

      state = AsyncData(Set<String>.from(_connectedDeviceIds));
      _syncForegroundService();
    });

    ref.read(deviceManagerProvider);
  }

  /// Runs the Android foreground service while at least one device is
  /// connected, so monitoring survives the app being backgrounded.
  void _syncForegroundService() {
    if (_connectedDeviceIds.isEmpty) {
      ForegroundServiceManager.stop();
    } else {
      ForegroundServiceManager.start();
    }
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

  Future<void> disconnectDevice(String deviceId) async {
    _deviceConnections[deviceId]?.cancel();
    _deviceConnections.remove(deviceId);
    if (_connectedDeviceIds.contains(deviceId)) {
      _connectedDeviceIds.remove(deviceId);
      state = AsyncData(Set<String>.from(_connectedDeviceIds));
    }
  }
}
