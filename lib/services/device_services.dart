import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/models/ble_service.dart';
import 'package:jackjack/models/ble_uuids.dart';
import 'package:jackjack/utils/env_manager.dart';

class DeviceServices {
  static Future<BLEDevice> create(
    DiscoveredDevice device,
    FlutterReactiveBle ble, {
    bool connected = true,
  }) async {
    final config = EnvManager.getInstanceSync();
    final created = <BLEService>[];
    Future<BLEService> make(
      BLEUUIDS uuid,
      BLEServiceType type, {
      bool? enabled,
    }) async {
      final active = enabled ?? connected;
      final service = BLEService(
        deviceId: device.id,
        uuid: uuid,
        type: type,
        client: ble,
        qualifiedCharacteristic:
            active
                ? QualifiedCharacteristic(
                  deviceId: device.id,
                  serviceId: Uuid.parse(uuid.service),
                  characteristicId: Uuid.parse(uuid.characteristic),
                )
                : null,
      );
      created.add(service);
      if (active) {
        try {
          await service.getValue();
          if (uuid.name == 'GET_BATTERY' &&
              (service.data is! int ||
                  service.data < 0 ||
                  service.data > 100)) {
            service.data = null;
          }
        } catch (_) {
          // A failed battery read does not disable sound-alert monitoring.
          if (uuid.name != 'GET_BATTERY') rethrow;
          service.data = null;
        }
      }
      return service;
    }

    try {
      final threshold = await make(
        config.getThresholdUUIDS,
        BLEServiceType.getInt,
      );
      if (connected &&
          (threshold.data is! int ||
              threshold.data < 30 ||
              threshold.data > 120)) {
        throw StateError(
          'Device returned an unsupported threshold; no automatic write was made',
        );
      }
      return BLEDevice(
        device: device,
        getThreshold: threshold,
        setThreshold: await make(
          config.setThresholdUUIDS,
          BLEServiceType.setInt,
        ),
        getBattery: await make(config.getBatteryUUIDS, BLEServiceType.getInt),
        thresholdAlert: await make(
          config.thresholdAlertUUIDS,
          BLEServiceType.stream,
        ),
        getSoundLevel: await make(
          config.getSoundLevelUUIDS,
          BLEServiceType.stream,
        ),
        setSoundLevel: await make(
          config.setSoundLevelUUIDS,
          BLEServiceType.setInt,
        ),
        // The supplied firmware has no live-audio characteristics.
        getSound: await make(
          config.getSoundUUIDS,
          BLEServiceType.stream,
          enabled: false,
        ),
        setSound: await make(
          config.setSoundUUIDS,
          BLEServiceType.setInt,
          enabled: false,
        ),
      );
    } catch (_) {
      for (final service in created) {
        await service.dispose();
      }
      rethrow;
    }
  }

  static Future<void> dispose(BLEDevice device) async {
    for (final service in [
      device.getThreshold,
      device.setThreshold,
      device.getBattery,
      device.thresholdAlert,
      device.getSoundLevel,
      device.setSoundLevel,
      device.getSound,
      device.setSound,
    ]) {
      await service.dispose();
    }
  }
}
