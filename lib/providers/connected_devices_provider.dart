import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/models/ble_service.dart';
import 'package:jackjack/providers/loading_provider.dart';
import 'package:jackjack/providers/paired_devices.dart';
import 'package:jackjack/providers/selected_device_provider.dart';
import 'package:jackjack/screens/pairing/pods/available_devices.dart';
import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:jackjack/utils/env_manager.dart';
import 'package:jackjack/utils/toast_manager.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:jackjack/providers/threshold_alert_provider.dart';

import '../utils/audio_stream_player.dart';

part 'connected_devices_provider.g.dart';

@Riverpod(keepAlive: true)
class ConnectedDevices extends _$ConnectedDevices {
  late final AudioStreamPlayer _audioPlayer;
  @override
  Map<String, BLEDevice> build() {
    _audioPlayer = AudioStreamPlayer();
    ref.onDispose(() => _audioPlayer.dispose());
    return {};
  }

  void playAudio() async {
    stopAudio();
    await _audioPlayer.initialize();
    await ref
        .read(connectedDevicesProvider)[ref.read(selectedDeviceProvider)]
        ?.setSound
        .setValue(1);
    await ref
        .read(connectedDevicesProvider)[ref.read(selectedDeviceProvider)]
        ?.getSound
        .getValue();
    _audioPlayer.start(
      // createTestAudioStream(8000)
      ref
          .read(connectedDevicesProvider)[ref.read(selectedDeviceProvider)]
          ?.getSound
          .data,
    );
  }

  Future<void> stopAudio() async {
    _audioPlayer.stop();
    await ref
        .read(connectedDevicesProvider)[ref.read(selectedDeviceProvider)]
        ?.setSound
        .setValue(0);
    await ref
        .read(connectedDevicesProvider)[ref.read(selectedDeviceProvider)]
        ?.getSound
        .getValue();
  }

  Future<void> removeDevice(String deviceId) async {
    final device = state[deviceId];
    if (device != null) {
      ref.read(loadingProvider(deviceId).notifier).toggle(true);
      state = {...state}..remove(deviceId);
      await device.dispose();
      ref.read(loadingProvider(deviceId).notifier).toggle(false);
    }
  }

  Future<void> connect(
    DiscoveredDevice device, {
    Duration timeout = const Duration(seconds: 35),
    bool shouldConnect = true,
  }) async {
    ref.read(loadingProvider(device.id).notifier).toggle(true);

    bool success = true;
    try {
      debugPrint("Should connect: $shouldConnect");
      debugPrint(state.keys.toString());
      final completer = Completer<void>();
      if (shouldConnect) {
        debugPrint("connect");
        if (!ref
            .read(connectedDevicesTrackerProvider.notifier)
            .isDeviceConnected(device.id)) {
          debugPrint("reactive ble connect");

          final subscription = FlutterReactiveBle()
              .connectToDevice(id: device.id, connectionTimeout: timeout)
              .listen(
                (connectionState) async {
                  debugPrint(
                    'Connection state: ${connectionState.connectionState}',
                  );

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
      success = false;
      debugPrint("Error: $e");
      ToastManager.show("Error: $e");
    }
    if (success) {
      await PairedDevicesUUID.saveToPrefs(device.id);
    }
    ref.read(loadingProvider(device.id).notifier).toggle(false);
    ref.read(deviceManagerProvider.notifier).updateDeviceStreams();
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
    BLEService? getSound;
    BLEService? setSound;

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
    if (getThreshold.data is int) {
      if (getThreshold.data < 30) {
        await setThreshold.setValue(30);
        await getThreshold.getValue();
      } else if (getThreshold.data > 120) {
        await setThreshold.setValue(120);
        await getThreshold.getValue();
      }
    }
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
    getSound = await BLEService.getService(
      EnvManager.getInstanceSync().getSoundUUIDS,
      BLEServiceType.stream,
      deviceId: device.id,
      deviceName: device.name,
      shouldConnect: shouldConnect,
    );
    setSound = await BLEService.getService(
      EnvManager.getInstanceSync().setSoundUUIDS,
      BLEServiceType.setInt,
      deviceId: device.id,
      deviceName: device.name,
      shouldConnect: shouldConnect,
    );
    debugPrint("Update");
    final BLEDevice? previousDevice = state[device.id];
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
      getSound: getSound!,
      setSound: setSound!,
    );
    debugPrint("1");
    state = oldState;
    // Tear down the previous device's stream subscriptions so re-discovering
    // or reconnecting a device doesn't leak BLE notification subscriptions.
    await previousDevice?.dispose();

    if (shouldConnect &&
        ref
            .read(connectedDevicesTrackerProvider.notifier)
            .isDeviceConnected(device.id)) {
      debugPrint(
        "------------------------------------------------------------------------------alert",
      );
      ref
          .read(thresholdAlertProvider.notifier)
          .setupDeviceAlert(device.id);
    }
  }
}
