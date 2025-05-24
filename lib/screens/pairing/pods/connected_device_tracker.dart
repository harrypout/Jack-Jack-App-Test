import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ble/screens/pairing/pods/available_devices.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
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

        // Create connection subscription for pre-existing connections
        if (!_deviceConnections.containsKey(connectionStateUpdate.deviceId)) {
          // Create a connection for tracking/management purposes
          final deviceId = connectionStateUpdate.deviceId;
          final subscription = _ble.connectToDevice(
            id: deviceId,
            connectionTimeout: const Duration(seconds: 5),
          ).listen((update) {
            // This subscription just monitors the existing connection
            if (update.connectionState == DeviceConnectionState.disconnected) {
              _connectedDeviceIds.remove(deviceId);
              state = AsyncData(Set<String>.from(_connectedDeviceIds));
            }
          });

          _deviceConnections[deviceId] = subscription;
          disconnectDevice(deviceId);
        }
      } else if (connectionStateUpdate.connectionState == DeviceConnectionState.disconnected) {
        _connectedDeviceIds.remove(connectionStateUpdate.deviceId);
      }
      state = AsyncData(Set<String>.from(_connectedDeviceIds));
    });

    final bleDevices = ref.read(deviceManagerProvider);
  }

  bool isDeviceConnected(String? deviceId) {
    return _connectedDeviceIds.contains(deviceId);
  }

  Set<String> get connectedDevices => _connectedDeviceIds;

  void storeConnectionSubscription(
    String deviceId,
    StreamSubscription subscription,
  ) {
    // Cancel existing subscription if any
    _deviceConnections[deviceId]?.cancel();

    // Store the new subscription
    _deviceConnections[deviceId] = subscription;
  }

  Future<void> disconnectDevice(String deviceId) async {
    // Cancel the connection subscription
    _deviceConnections[deviceId]?.cancel();
    _deviceConnections.remove(deviceId);

    // Update tracked state immediately for UI responsiveness
    if (_connectedDeviceIds.contains(deviceId)) {
      _connectedDeviceIds.remove(deviceId);
      state = AsyncData(Set<String>.from(_connectedDeviceIds));
    }
  }
}

// // import 'dart:typed_data';
// import 'dart:async';
// // import 'package:ble/providers/connected_devices_provider.dart';
// import 'package:ble/screens/pairing/pods/available_devices.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';
// // import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// // import '../../../utils/env_manager.dart';
//
// part 'connected_device_tracker.g.dart';
//
// /// Detects BLE devices connected at system level and brings them under app management
// // Future<void> adoptSystemConnectedDevices(AsyncNotifierProviderRef<Set<String>> ref) async {
// //   try {
// //     debugPrint('Checking for system-connected BLE devices...');
// //
// //     // Get system-connected devices with our service UUID
// //     final connectedDevices = await FlutterBluePlus.systemDevices([
// //       Guid(configs.setThresholdUUIDS.service),
// //     ]);
// //
// //     if (connectedDevices.isEmpty) {
// //       debugPrint('No system-level BLE connections found');
// //       return;
// //     }
// //
// //     debugPrint('Found ${connectedDevices.length} system-connected devices');
// //
// //     // Use the provided ref instead of creating a new container
// //     final provider = ref.read(connectedDevicesProvider.notifier);
// //
// //     // Register each device with the connection provider
// //     for (final fbpDevice in connectedDevices) {
// //       final deviceId = fbpDevice.remoteId.toString();
// //       debugPrint('Adopting system-connected device: $deviceId');
// //
// //       try {
// //         // Convert FlutterBluePlus device to DiscoveredDevice for the provider
// //         final discoveredDevice = DiscoveredDevice(
// //           id: deviceId,
// //           name: fbpDevice.platformName,
// //           serviceData: const {},
// //           manufacturerData: Uint8List(0),
// //           rssi: -50,
// //           serviceUuids: [Uuid.parse(configs.setThresholdUUIDS.service)],
// //         );
// //
// //         // Register with your existing connection management system
// //         await provider.connect(
// //           discoveredDevice,
// //           shouldConnect: true,
// //         );
// //
// //         debugPrint('Successfully adopted device: $deviceId');
// //       } catch (e) {
// //         debugPrint('Failed to adopt device $deviceId: $e');
// //       }
// //     }
// //   } catch (e) {
// //     debugPrint('Error adopting system connections: $e');
// //   }
// // }
//
// @Riverpod(keepAlive: true)
// class ConnectedDevicesTracker extends _$ConnectedDevicesTracker {
//   final FlutterReactiveBle _ble = FlutterReactiveBle();
//   final Set<String> _connectedDeviceIds = {};
//   StreamSubscription? _connectionSubscription;
//   final Map<String, StreamSubscription> _deviceConnections = {};
//
//   @override
//   FutureOr<Set<String>> build() {
//     debugPrint("Building connected devices tracker...");
//     _initialize();
//
//     ref.onDispose(() {
//       _connectionSubscription?.cancel();
//       for (final subscription in _deviceConnections.values) {
//         subscription.cancel();
//       }
//     });
//
//     return _connectedDeviceIds;
//   }
//
//   Future<void> _initialize() async {
//     debugPrint("Initializing connected devices tracker...");
//     _connectionSubscription = _ble.connectedDeviceStream.listen((
//       connectionStateUpdate
//     ) {
//       debugPrint("-----------------------------------------------------------------------$connectionStateUpdate");
//       if (connectionStateUpdate.connectionState ==
//           DeviceConnectionState.connected) {
//         debugPrint('Connected to device: ${connectionStateUpdate.deviceId}');
//         _connectedDeviceIds.add(connectionStateUpdate.deviceId);
//       } else if (connectionStateUpdate.connectionState ==
//           DeviceConnectionState.disconnected) {
//         _connectedDeviceIds.remove(connectionStateUpdate.deviceId);
//       }
//       state = AsyncData(Set<String>.from(_connectedDeviceIds));
//     });
//
//     final bleDevices = ref.read(deviceManagerProvider);
//     // await adoptSystemConnectedDevices(ref);
//   }
//
//   bool isDeviceConnected(String deviceId) {
//     return _connectedDeviceIds.contains(deviceId);
//   }
//
//   Set<String> get connectedDevices => _connectedDeviceIds;
//
//   void storeConnectionSubscription(
//     String deviceId,
//     StreamSubscription subscription,
//   ) {
//     // Cancel existing subscription if any
//     _deviceConnections[deviceId]?.cancel();
//
//     // Store the new subscription
//     _deviceConnections[deviceId] = subscription;
//   }
//
//   Future<void> disconnectDevice(String deviceId) async {
//     // Cancel the connection subscription
//     _deviceConnections[deviceId]?.cancel();
//     _deviceConnections.remove(deviceId);
//
//     // Update tracked state immediately for UI responsiveness
//     if (_connectedDeviceIds.contains(deviceId)) {
//       _connectedDeviceIds.remove(deviceId);
//       state = AsyncData(Set<String>.from(_connectedDeviceIds));
//     }
//   }
// }
