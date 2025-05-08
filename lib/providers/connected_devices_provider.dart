import 'dart:io';
import 'package:ble/models/ble_device.dart';
import 'package:ble/models/ble_service.dart';
import 'package:ble/providers/loading_provider.dart';
import 'package:ble/utils/env_manager.dart';
import 'package:ble/utils/toast_manager.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ble/providers/threshold_alert_provider.dart';

part 'connected_devices_provider.g.dart';

@Riverpod(keepAlive: true)
class ConnectedDevices extends _$ConnectedDevices {
  @override
  Map<String, BLEDevice> build() => {};

  Future<void> connect(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 35),
    bool shouldConnect = true,
  }) async {
    ref.read(loadingProvider(device.remoteId.str).notifier).toggle(true);
    try {
      print("Should connect: $shouldConnect");
      print(state.keys);
      List<BluetoothService> services = [];

      if (shouldConnect) {
        print("connect");
        if (device.isDisconnected) {
          await device.connect(timeout: timeout);
          print("bond");
          if (Platform.isAndroid) {
            await device.createBond();
          }
        }

        if (device.isConnected) {
          // await PairedDevicesUUID.saveToPrefs(device.remoteId.str);
          print("services");
          services = await device.discoverServices();
          for (var service in services) {
            print("Service: ${service.toString()}");
          }
          for (var action in state.keys) {
            print(state[action]?.device);
          }
        }
      } else {
        if (device.isConnected) {
          await device.disconnect();
        }
      }
      print("Update");
      Map<String, BLEDevice> oldState = {};
      oldState.addAll(state);
      oldState[device.remoteId.str] = BLEDevice(
        device: device,
        getThreshold: await BLEService.getService(
          services,
          EnvManager.getInstanceSync().getThresholdUUIDS,
          BLEServiceType.getInt,
          deviceName: device.platformName,
          shouldConnect: shouldConnect,
        ),
        setThreshold: await BLEService.getService(
          services,
          EnvManager.getInstanceSync().setThresholdUUIDS,
          BLEServiceType.setInt,
          deviceName: device.platformName,
          shouldConnect: shouldConnect,
        ),
        getBattery: await BLEService.getService(
          services,
          EnvManager.getInstanceSync().getBatteryUUIDS,
          BLEServiceType.getInt,
          deviceName: device.platformName,
          shouldConnect: shouldConnect,
        ),
        thresholdAlert: await BLEService.getService(
          services,
          EnvManager.getInstanceSync().thresholdAlertUUIDS,
          BLEServiceType.stream,
          deviceName: device.platformName,
          shouldConnect: shouldConnect,
        ),
        getSoundLevel: await BLEService.getService(
          services,
          EnvManager.getInstanceSync().getSoundLevelUUIDS,
          BLEServiceType.stream,
          deviceName: device.platformName,
          shouldConnect: shouldConnect,
        ),
        setSoundLevel: await BLEService.getService(
          services,
          EnvManager.getInstanceSync().setSoundLevelUUIDS,
          BLEServiceType.setInt,
          deviceName: device.platformName,
          shouldConnect: shouldConnect,
        ),
      );
      state = oldState;
      if (shouldConnect && device.isConnected) {
        print(
          "------------------------------------------------------------------------------alert",
        );
        ref
            .read(thresholdAlertProvider.notifier)
            .setupDeviceAlert(
              device.remoteId.str,
              oldState[device.remoteId.str]!,
            );
      }
    } catch (e) {
      print("Error: $e");
      ToastManager.show(
        "Error: $e",
      );
    }
    ref.read(loadingProvider(device.remoteId.str).notifier).toggle(false);
  }
}
