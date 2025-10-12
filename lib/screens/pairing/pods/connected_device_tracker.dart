import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/screens/pairing/pods/available_devices.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
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
    });

    return _connectedDeviceIds;
  }

  Future<void> _initialize() async {
    debugPrint("Initializing connected devices tracker...");
    _connectionSubscription = _ble.connectedDeviceStream.listen((connectionStateUpdate) {
      debugPrint("-----------------------------------------------------------------------$connectionStateUpdate");
      if (connectionStateUpdate.connectionState == DeviceConnectionState.connected) {
        debugPrint('Connected to device: ${connectionStateUpdate.deviceId}');
        _connectedDeviceIds.add(connectionStateUpdate.deviceId);
        if (!_deviceConnections.containsKey(connectionStateUpdate.deviceId)) {
          final deviceId = connectionStateUpdate.deviceId;
          final subscription = _ble.connectToDevice(
            id: deviceId,
            connectionTimeout: const Duration(seconds: 5),
          ).listen((update) {
            if (update.connectionState == DeviceConnectionState.disconnected) {
              _connectedDeviceIds.remove(deviceId);
              state = AsyncData(Set<String>.from(_connectedDeviceIds));
            }
          });

          _deviceConnections[deviceId] = subscription;
          disconnectDevice(deviceId);
        }
      } else if (connectionStateUpdate.connectionState == DeviceConnectionState.disconnected) {
        if(_connectedDeviceIds.contains(connectionStateUpdate.deviceId))
        {
          final disconnectedDevice = ref.read(
              connectedDevicesProvider)[connectionStateUpdate.deviceId];
          NotificationManager.instance.showDisconnectionAlert(
            deviceId: disconnectedDevice!.device.id,
            deviceName: disconnectedDevice.device.name,
          );
        }
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

  Future<void> disconnectDevice(String deviceId) async {
    _deviceConnections[deviceId]?.cancel();
    _deviceConnections.remove(deviceId);
    if (_connectedDeviceIds.contains(deviceId)) {
      _connectedDeviceIds.remove(deviceId);
      state = AsyncData(Set<String>.from(_connectedDeviceIds));
    }
  }
}
