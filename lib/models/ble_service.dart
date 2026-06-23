import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jackjack/models/ble_uuids.dart';
import 'package:jackjack/utils/toast_manager.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

enum BLEServiceType { getInt, setInt, stream }

class BLEService {
  String deviceId;
  QualifiedCharacteristic? qualifiedCharacteristic;
  BLEServiceType type;
  BLEUUIDS uuid;
  StreamController<int>? _streamController;
  StreamSubscription<List<int>>? _notificationSubscription;
  dynamic data;
  BLEService({
    required this.deviceId,
    this.qualifiedCharacteristic,
    required this.uuid,
    required this.type,
    this.data,
  });
  BLEService copyWith({
    String? deviceId,
    QualifiedCharacteristic? qualifiedCharacteristic,
    BLEUUIDS? uuid,
    BLEServiceType? type,
    dynamic data,
  }) {
    return BLEService(
      deviceId: deviceId ?? this.deviceId,
      qualifiedCharacteristic:
          qualifiedCharacteristic ?? this.qualifiedCharacteristic,
      uuid: uuid ?? this.uuid,
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }

  @override
  String toString() =>
      'BLEService(deviceId: $deviceId, qualifiedCharacteristic: $qualifiedCharacteristic, uuid: $uuid, type: $type, data: $data)';

  static Future<BLEService> getService(
    BLEUUIDS targetService,
    BLEServiceType serviceType, {
    required String deviceId,
    required String deviceName,
    required bool shouldConnect,
  }) async {
    debugPrint("Getting service: ${targetService.name}");
    debugPrint("Service: ${targetService.service}");
    debugPrint("Characteristic: ${targetService.characteristic}");
    BLEService newService = BLEService(
      deviceId: deviceId,
      qualifiedCharacteristic:
          shouldConnect
              ? QualifiedCharacteristic(
                serviceId: Uuid.parse(targetService.service),
                characteristicId: Uuid.parse(targetService.characteristic),
                deviceId: deviceId,
              )
              : null,
      uuid: targetService,
      type: serviceType,
      data: serviceType == BLEServiceType.stream ? Stream.value(0) : 0,
    );
    try {
      await newService.getValue();
    } catch (e,s) {
      if (e is int && (e == 0 || e == 1)) {
        debugPrint(
          "$deviceName: ${e == 0 ? "Service" : "Characteristic"} ${targetService.name} not found",
        );
        ToastManager.show(
          "$deviceName: ${e == 0 ? "Service" : "Characteristic"} ${targetService.name} not found",
        );
      } else {
        debugPrint("Get Service: $deviceName: $e\n$s");
        ToastManager.show("$deviceName: $e");
      }
    }
    return newService;
  }

  Future<void> getValue() async {
    debugPrint("Old Get Value: ${toString()}");
    if (type == BLEServiceType.stream) {
      if (qualifiedCharacteristic == null) {
        data = Stream<int>.value(0).asBroadcastStream();
      } else {
        // Create notification stream using flutter_reactive_ble. The
        // underlying subscription is owned by this BLEService so it can be
        // cancelled in dispose(); otherwise a default broadcast stream keeps
        // its source subscription alive forever and leaks on every reconnect.
        try {
          await _notificationSubscription?.cancel();
          await _streamController?.close();
          final controller = StreamController<int>.broadcast();
          _streamController = controller;
          _notificationSubscription = FlutterReactiveBle()
              .subscribeToCharacteristic(qualifiedCharacteristic!)
              .listen(
                (List<int> values) {
                  if (!controller.isClosed) {
                    controller.add(values.isNotEmpty ? values[0] : 0);
                  }
                },
                onError: (e) {
                  debugPrint("Notification stream error: $e");
                },
              );
          data = controller.stream;
        } catch (e) {
          debugPrint("Notification subscription error: $e");
          data = Stream<int>.value(0).asBroadcastStream();
        }
      }
    } else if (type == BLEServiceType.getInt) {
      if (qualifiedCharacteristic != null) {
        try {
          List<int> byteData = await FlutterReactiveBle().readCharacteristic(
            qualifiedCharacteristic!,
          );
          for (var byte in byteData) {
            debugPrint(byte.toString());
          }
          data = byteData.isNotEmpty ? byteData[0] : 0;
        } catch (e) {
          debugPrint("Read error: $e");
          data = 0;
        }
      }
    }
    debugPrint("New Get Value: ${data.toString()}");
  }

  Future<void> setValue(int value) async {
    final FlutterReactiveBle ble = FlutterReactiveBle();
    debugPrint("Setting value: $type, value: $value");
    if (type == BLEServiceType.setInt) {
      debugPrint("Setting");
      debugPrint("set ${uuid.name} int");

      if (qualifiedCharacteristic != null) {
        try {
          await ble.writeCharacteristicWithResponse(
            qualifiedCharacteristic!,
            value: [value],
          );
          debugPrint("Write successful");
        } catch (e) {
          debugPrint("Write error: $e");
          rethrow;
        }
      } else {
        debugPrint("Cannot write: characteristic is null");
      }
    }
  }

  /// Cancels the underlying BLE notification subscription (if any) and closes
  /// the broadcast controller. Safe to call on non-stream services (no-op).
  Future<void> dispose() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    await _streamController?.close();
    _streamController = null;
  }
}
