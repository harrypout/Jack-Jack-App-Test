import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ble/models/ble_device.dart';
import 'package:ble/models/ble_service.dart';
import 'package:ble/providers/loading_provider.dart';
import 'package:ble/providers/paired_devices.dart';
import 'package:ble/screens/pairing/pods/available_devices.dart';
import 'package:ble/screens/pairing/pods/connected_device_tracker.dart';
import 'package:ble/utils/env_manager.dart';
import 'package:ble/utils/toast_manager.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ble/providers/threshold_alert_provider.dart';

part 'connected_devices_provider.g.dart';

@Riverpod(keepAlive: true)
class ConnectedDevices extends _$ConnectedDevices {
  @override
  Map<String, BLEDevice> build() => {};

  Future<void> removeDevice(String deviceId) async {
    if (state[deviceId] != null) {
      ref.read(loadingProvider(deviceId).notifier).toggle(true);
      state.remove(deviceId);
      ref.read(loadingProvider(deviceId).notifier).toggle(false);
    }
  }

  Future<void> connect(
    DiscoveredDevice device, {
    Duration timeout = const Duration(seconds: 35),
    bool shouldConnect = true,
  }) async {
    ref.read(loadingProvider(device.id).notifier).toggle(true);

    try {
      debugPrint("Should connect: $shouldConnect");
      debugPrint(state.keys.toString());
      // List<BluetoothService> services = [];
      final completer = Completer<void>();
      if (shouldConnect) {
        debugPrint("connect");
        if (!ref
            .read(connectedDevicesTrackerProvider.notifier)
            .isDeviceConnected(device.id)) {
          debugPrint("reactive ble connect");
          // Create connection and store subscription

          final subscription = FlutterReactiveBle()
              .connectToDevice(id: device.id, connectionTimeout: timeout)
              .listen(
                (connectionState) async {
                  // Here you can respond to connection state changes
                  debugPrint('Connection state: ${connectionState.connectionState}');

                  if (connectionState.connectionState ==
                      DeviceConnectionState.connected) {
                    debugPrint("connected");
                    if (!completer.isCompleted) {
                      debugPrint("completer complete");
                      completer.complete();
                    }
                  }
                },
                onError: (error, stackTrace) {
                  if (!completer.isCompleted) {
                    completer.completeError(error);
                    debugPrint("Error: $error");
                    throw error;
                  }
                },
              );
          debugPrint("storing connection");
          ref
              .read(connectedDevicesTrackerProvider.notifier)
              .storeConnectionSubscription(device.id, subscription);
        } else {
          debugPrint("not connected");
          if (!completer.isCompleted) {
            completer.completeError("not connected");
            debugPrint("Error: not connected");
            throw "not connected";
          }
        }
      } else {
        if (ref
            .read(connectedDevicesTrackerProvider.notifier)
            .isDeviceConnected(device.id)) {
          await ref
              .read(connectedDevicesTrackerProvider.notifier)
              .disconnectDevice(device.id);
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      await completer.future;
      debugPrint("get services");
      //get services function here
      await getServices(device, shouldConnect: shouldConnect);
    } catch (e) {
      debugPrint("Error: $e");
      ToastManager.show("Error: $e");
    }
    await PairedDevicesUUID.saveToPrefs(device.id);
    ref.read(loadingProvider(device.id).notifier).toggle(false);
    ref.read(deviceManagerProvider.notifier).updateDeviceStreams();
    // ref.refresh(deviceManagerProvider);
    // ref.read(deviceManagerProvider.notifier).state= ref.read(deviceManagerProvider.notifier).fetchDevices();
  }

  Future<void> getServices(
    DiscoveredDevice device, {
    bool shouldConnect = true,
  }) async {
    BLEService? getThreshold;
    BLEService? setThreshold;
    BLEService? getBattery;
    BLEService? thresholdAlert;
    BLEService? getSoundLevel;
    BLEService? setSoundLevel;

    getThreshold = await BLEService.getService(
      EnvManager.getInstanceSync().getThresholdUUIDS,
      BLEServiceType.getInt,
      deviceId: device.id,
      deviceName: device.name,
      shouldConnect: shouldConnect,
    );
    setThreshold = await BLEService.getService(
      EnvManager.getInstanceSync().setThresholdUUIDS,
      BLEServiceType.setInt,
      deviceId: device.id,
      deviceName: device.name,
      shouldConnect: shouldConnect,
    );
    getBattery = await BLEService.getService(
      EnvManager.getInstanceSync().getBatteryUUIDS,
      BLEServiceType.getInt,
      deviceId: device.id,
      deviceName: device.name,
      shouldConnect: shouldConnect,
    );
    thresholdAlert = await BLEService.getService(
      EnvManager.getInstanceSync().thresholdAlertUUIDS,
      BLEServiceType.stream,
      deviceId: device.id,
      deviceName: device.name,
      shouldConnect: shouldConnect,
    );
    getSoundLevel = await BLEService.getService(
      EnvManager.getInstanceSync().getSoundLevelUUIDS,
      BLEServiceType.stream,
      deviceId: device.id,
      deviceName: device.name,
      shouldConnect: shouldConnect,
    );
    setSoundLevel = await BLEService.getService(
      EnvManager.getInstanceSync().setSoundLevelUUIDS,
      BLEServiceType.setInt,
      deviceId: device.id,
      deviceName: device.name,
      shouldConnect: shouldConnect,
    );
    debugPrint("Update");
    Map<String, BLEDevice> oldState = {};
    oldState.addAll(state);
    oldState[device.id] = BLEDevice(
      device: device,
      getThreshold: getThreshold!,
      setThreshold: setThreshold!,
      getBattery: getBattery!,
      thresholdAlert: thresholdAlert!,
      getSoundLevel: getSoundLevel!,
      setSoundLevel: setSoundLevel!,
    );
    debugPrint("1");
    state = oldState;

    if (shouldConnect &&
        ref
            .read(connectedDevicesTrackerProvider.notifier)
            .isDeviceConnected(device.id)) {
      debugPrint(
        "------------------------------------------------------------------------------alert",
      );
      ref
          .read(thresholdAlertProvider.notifier)
          .setupDeviceAlert(device.id, oldState[device.id]!);
    }
  }
}
