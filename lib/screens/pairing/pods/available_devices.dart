import 'dart:async';
import 'package:ble/main.dart';
import 'package:ble/providers/connected_devices_provider.dart';
import 'package:ble/providers/paired_devices.dart';
import 'package:ble/utils/env_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'connected_device_tracker.dart';

part 'available_devices.g.dart';

@riverpod
class DeviceManager extends _$DeviceManager {
  StreamSubscription? _scanSubscription;
  final Map<String, DiscoveredDevice> _discoveredDevices = {};

  // Replace stream controllers with simple lists
  List<DiscoveredDevice> _pairedDevices = [];
  List<DiscoveredDevice> _availableDevices = [];

  @override
  BLEDevices build() {
    debugPrint("DeviceManager build");

    // Create the BLEDevices object with lists
    final bleDevices = BLEDevices(
      available: _availableDevices,
      paired: _pairedDevices,
    );

    // Start scanning for devices
    _startScan();

    // Clean up when provider is disposed
    ref.onDispose(() {
      debugPrint("DeviceManager dispose");
      _scanSubscription?.cancel();
    });

    return bleDevices;
  }

  void _startScan() {
    try {
      debugPrint("Starting scan");
      updateDeviceStreams();
      _scanSubscription = FlutterReactiveBle()
          .scanForDevices(
            withServices: [Uuid.parse(configs.setThresholdUUIDS.service)],
            scanMode: ScanMode.lowLatency,
          )
          .listen((device) {
            if (_discoveredDevices[device.id] == null) {
              debugPrint("Device found: $device");
              // Store device to avoid duplicates
              _discoveredDevices[device.id] = device;

              // Update device lists
              updateDeviceStreams();
            }
          });
    } catch (e, s) {
      debugPrint("Scan error: $e\n$s");
    }
  }

  void updateDeviceStreams() {
    Future.microtask(() async {
      debugPrint("Updating device lists");

      try {
        await PairedDevicesUUID.loadFromPrefs();

        final newPairedDevices = <DiscoveredDevice>[];
        final newAvailableDevices = <DiscoveredDevice>[];

        debugPrint("Total discovered devices: ${_discoveredDevices.length}");
        final pairedIds = PairedDevicesUUID.getList;
        for (final device in _discoveredDevices.values) {
          if (pairedIds.contains(device.id)) {
            debugPrint("Paired device: ${device.name} (${device.id})");
            newPairedDevices.add(device);
            if (!ref.read(connectedDevicesProvider).keys.contains(device.id)) {
              debugPrint("Connecting to paired device: ${device.id}");
              await ref
                  .read(connectedDevicesProvider.notifier)
                  .connect(device, shouldConnect: prefs.getBool("autoConnect")?? false)
                  .catchError((error) {
                    debugPrint("Error connecting to device ${device.id}: $error");
                  });
            }
          } else {
            debugPrint("Available device: ${device.name} (${device.id})");
            newAvailableDevices.add(device);
            if (ref.read(connectedDevicesProvider).keys.contains(device.id)) {
              ref
                  .read(connectedDevicesProvider.notifier)
                  .removeDevice(device.id);
            }
          }
        }
        final connectedDeviceIds =
            ref.read(connectedDevicesTrackerProvider).value ?? <String>{};
        debugPrint("Connected devices from tracker: $connectedDeviceIds");

        for (final deviceId in connectedDeviceIds) {
          if (newPairedDevices.any((device) => device.id == deviceId)) {
            continue;
          }
          final discoveredDevice = _discoveredDevices[deviceId];
          if (discoveredDevice != null) {
            debugPrint(
              "Moving connected device to paired list: ${discoveredDevice.name} (${discoveredDevice.id})",
            );
            newPairedDevices.add(discoveredDevice);
            newAvailableDevices.removeWhere((device) => device.id == deviceId);
            await PairedDevicesUUID.saveToPrefs(deviceId);
          }
        }
        _pairedDevices = newPairedDevices;
        _availableDevices = newAvailableDevices;
        state = BLEDevices(
          available: _availableDevices,
          paired: _pairedDevices,
        );
      } catch (e, stackTrace) {
        debugPrint("Error updating device lists: $e\n$stackTrace");
      }
    });
  }

  Future<void> addPairedDevice(DiscoveredDevice device) async {
    debugPrint("Manually adding paired device: ${device.name} (${device.id})");
    if (_pairedDevices.any((pairedDevice) => pairedDevice.id == device.id)) {
      debugPrint("Device already paired: ${device.name} (${device.id})");
      return;
    }
    if (_discoveredDevices[device.id] == null) {
      _discoveredDevices[device.id] = device;
    }
    await ref.read(connectedDevicesProvider.notifier).getServices(device);
    _pairedDevices = [..._pairedDevices, device];
    state = BLEDevices(available: _availableDevices, paired: _pairedDevices);
  }

  void refreshScan() {
    debugPrint("Refreshing scan");
    _scanSubscription?.cancel();
    _startScan();
  }
}

class BLEDevices {
  final List<DiscoveredDevice> available;
  final List<DiscoveredDevice> paired;

  BLEDevices({required this.available, required this.paired});
}