import 'dart:async';
import 'package:jackjack/main.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/providers/paired_devices.dart';
import 'package:jackjack/utils/env_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'connected_device_tracker.dart';

part 'available_devices.g.dart';

@riverpod
class DeviceManager extends _$DeviceManager {
  StreamSubscription? _scanSubscription;
  Timer? _scanCycleTimer;
  Timer? _updateDebounceTimer;
  bool _isScanning = false;
  bool _isStopped = false;
  bool _isUpdating = false;
  final Map<String, DiscoveredDevice> _discoveredDevices = {};

  List<DiscoveredDevice> _pairedDevices = [];
  List<DiscoveredDevice> _availableDevices = [];

  @override
  BLEDevices build() {
    debugPrint("DeviceManager build");
    final bleDevices = BLEDevices(
      available: _availableDevices,
      paired: _pairedDevices,
    );
    _isStopped = false;
    _startScan();
    ref.onDispose(() {
      debugPrint("DeviceManager dispose");
      _scanCycleTimer?.cancel();
      _scanSubscription?.cancel();
      _updateDebounceTimer?.cancel();
    });

    return bleDevices;
  }

  void _startScan() {
    if (_isScanning) return; // Prevent double-start
    if (_isStopped) return; // Don't start if explicitly stopped

    try {
      debugPrint("Starting 35-second scan");
      _isScanning = true;

      // Clear discovered devices at start of each scan cycle
      _discoveredDevices.clear();

      updateDeviceStreams();
      _scanSubscription = FlutterReactiveBle()
          .scanForDevices(
            withServices: [Uuid.parse(configs.setThresholdUUIDS.service)],
            scanMode: ScanMode.lowLatency,
          )
          .listen((device) {
            if (_discoveredDevices[device.id] == null) {
              debugPrint("Device found: $device");
              _discoveredDevices[device.id] = device;
              updateDeviceStreams();
            }
          });

      // Stop scan after 35 seconds, wait 5 seconds, then restart
      _scanCycleTimer?.cancel();
      _scanCycleTimer = Timer(const Duration(seconds: 35), () async {
        debugPrint("35-second scan complete, pausing for 5 seconds");
        await _scanSubscription?.cancel();
        _isScanning = false;

        // Wait 5 seconds before restarting scan
        await Future.delayed(const Duration(seconds: 5));
        _startScan(); // Restart the cycle
      });
    } catch (e, s) {
      debugPrint("Scan error: $e\n$s");
      _isScanning = false;
    }
  }

  void updateDeviceStreams() {
    // Debounce: cancel pending update and schedule new one
    _updateDebounceTimer?.cancel();
    _updateDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_isUpdating) return; // Skip if already updating
      _isUpdating = true;

      try {
        debugPrint("Updating device lists");
        await PairedDevicesUUID.loadFromPrefs();

        final newPairedDevices = <DiscoveredDevice>[];
        final newAvailableDevices = <DiscoveredDevice>[];

        debugPrint("Total discovered devices: ${_discoveredDevices.length}");
        final pairedIds = PairedDevicesUUID.getList;
        for (final device in _discoveredDevices.values) {
          if (pairedIds.contains(device.id)) {
            debugPrint("Paired device: ${device.name} (${device.id})");
            newPairedDevices.add(device);

            // Only auto-connect if NOT already connected and auto-connect enabled
            // Check BOTH providers: physical connection AND service initialization
            final isPhysicallyConnected = ref.read(connectedDevicesTrackerProvider).value?.contains(device.id) ?? false;
            final hasServices = ref.read(connectedDevicesProvider).keys.contains(device.id);
            final isConnected = isPhysicallyConnected && hasServices;

            // Check if user manually disconnected this device
            final userDisconnected = prefs.getBool("user_disconnected_${device.id}") ?? false;

            if (!isConnected && (prefs.getBool("autoConnect") ?? false) && !userDisconnected) {
              debugPrint("Auto-connecting to paired device: ${device.id}");
              ref
                  .read(connectedDevicesProvider.notifier)
                  .connect(device, shouldConnect: true)
                  .catchError((error) {
                    debugPrint("Error auto-connecting to ${device.id}: $error");
                  });
            } else if (!hasServices && userDisconnected) {
              // User manually disconnected - add to provider but don't physically connect
              debugPrint("Skipping auto-connect for ${device.id} - user manually disconnected");
              ref
                  .read(connectedDevicesProvider.notifier)
                  .connect(device, shouldConnect: false)
                  .catchError((error) {
                    debugPrint("Error registering device ${device.id}: $error");
                  });
            } else if (!hasServices) {
              // Paired device found in scan but not in provider — register it
              // so it shows on home screen. Uses getServices directly to avoid
              // connect(shouldConnect: false) which would set user_disconnected flag.
              debugPrint("Registering paired device ${device.id} in provider");
              ref
                  .read(connectedDevicesProvider.notifier)
                  .getServices(device, shouldConnect: false);
            }
          } else {
            debugPrint("Available device: ${device.name} (${device.id})");
            newAvailableDevices.add(device);
            if (ref.read(connectedDevicesProvider).keys.contains(device.id)) {
              ref.read(connectedDevicesProvider.notifier).removeDevice(device.id);
            }
          }
        }

        // Handle already-connected devices from tracker
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

        // Clean up devices from connectedDevicesProvider that weren't found in scan
        // (out of range or powered off).
        // Skip cleanup when discovered devices is empty — scan just started and
        // hasn't had time to find anything yet.
        if (_discoveredDevices.isNotEmpty) {
          final allScannedDeviceIds = _discoveredDevices.keys.toSet();
          final devicesInProvider = ref.read(connectedDevicesProvider).keys.toSet();
          final devicesToRemove = devicesInProvider.difference(allScannedDeviceIds);

          for (final deviceId in devicesToRemove) {
            // Only remove if device is also not physically connected
            final isPhysicallyConnected = connectedDeviceIds.contains(deviceId);
            if (!isPhysicallyConnected) {
              debugPrint("Removing device from provider (not found in scan): $deviceId");
              await ref.read(connectedDevicesProvider.notifier).removeDevice(deviceId);
            }
          }
        }

        // Update state after cleanup to ensure UI refreshes
        state = BLEDevices(
          available: _availableDevices,
          paired: _pairedDevices,
        );
      } catch (e, stackTrace) {
        debugPrint("Error updating device lists: $e\n$stackTrace");
      } finally {
        _isUpdating = false;
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

  void stopScan() {
    debugPrint("Stopping scan");
    _scanCycleTimer?.cancel();
    _scanSubscription?.cancel();
    _updateDebounceTimer?.cancel();
    _isScanning = false;
    _isStopped = true;
  }

  void refreshScan() {
    debugPrint("Refreshing scan");
    _scanCycleTimer?.cancel();
    _scanSubscription?.cancel();
    _isScanning = false;
    _isStopped = false;
    // Don't clear discovered devices - keep them to avoid reconnection issues
    _startScan();
  }
}

class BLEDevices {
  final List<DiscoveredDevice> available;
  final List<DiscoveredDevice> paired;

  BLEDevices({required this.available, required this.paired});
}