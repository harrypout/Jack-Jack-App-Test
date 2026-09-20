import 'dart:async';
import 'dart:typed_data';
import 'package:jackjack/models/ble_uuids.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

enum BLEServiceType { getInt, setInt, stream }

/// One GATT characteristic in one connection session. A new connection must
/// create new services; disposing a service releases its native subscription.
class BLEService {
  final FlutterReactiveBle? _client;
  FlutterReactiveBle get _ble => _client ?? FlutterReactiveBle();
  final String deviceId;
  QualifiedCharacteristic? qualifiedCharacteristic;
  final BLEServiceType type;
  final BLEUUIDS uuid;
  dynamic data;
  StreamSubscription<List<int>>? _subscription;
  StreamController<int>? _controller;

  BLEService({
    required this.deviceId,
    this.qualifiedCharacteristic,
    required this.uuid,
    required this.type,
    this.data,
    FlutterReactiveBle? client,
  }) : _client = client;

  BLEService copyWith({
    String? deviceId,
    QualifiedCharacteristic? qualifiedCharacteristic,
    BLEUUIDS? uuid,
    BLEServiceType? type,
    dynamic data,
  }) => BLEService(
    deviceId: deviceId ?? this.deviceId,
    qualifiedCharacteristic:
        qualifiedCharacteristic ?? this.qualifiedCharacteristic,
    uuid: uuid ?? this.uuid,
    type: type ?? this.type,
    data: data ?? this.data,
    client: _client,
  );

  static Future<BLEService> getService(
    BLEUUIDS targetService,
    BLEServiceType serviceType, {
    required String deviceId,
    required String deviceName,
    required bool shouldConnect,
    FlutterReactiveBle? client,
  }) async {
    final service = BLEService(
      deviceId: deviceId,
      client: client,
      uuid: targetService,
      type: serviceType,
      qualifiedCharacteristic:
          shouldConnect
              ? QualifiedCharacteristic(
                serviceId: Uuid.parse(targetService.service),
                characteristicId: Uuid.parse(targetService.characteristic),
                deviceId: deviceId,
              )
              : null,
    );
    if (shouldConnect) await service.getValue();
    return service;
  }

  int _decode(List<int> bytes) {
    final sound = uuid.name == 'GET_SOUND_LEVEL';
    if (bytes.length != (sound ? 2 : 1) || bytes.any((b) => b < 0 || b > 255)) {
      throw FormatException('Invalid ${uuid.name} packet length or byte value');
    }
    return sound
        ? ByteData.sublistView(
          Uint8List.fromList(bytes),
        ).getInt16(0, Endian.little)
        : bytes.single;
  }

  Future<void> getValue() async {
    final characteristic = qualifiedCharacteristic;
    if (characteristic == null) throw StateError('Device is not connected');
    if (type == BLEServiceType.getInt) {
      // Preserve the last confirmed value if the read fails. Callers explicitly
      // invalidate freshness; a failed read must never become a hardware zero.
      data = _decode(
        await _ble
            .readCharacteristic(characteristic)
            .timeout(const Duration(seconds: 10)),
      );
    } else if (type == BLEServiceType.stream) {
      if (_controller != null) return;
      late StreamController<int> controller;
      controller = StreamController<int>.broadcast(
        onListen: () {
          _subscription = _ble
              .subscribeToCharacteristic(characteristic)
              .listen(
                (bytes) {
                  try {
                    controller.add(_decode(bytes));
                  } catch (error, stack) {
                    controller.addError(error, stack);
                  }
                },
                onError: controller.addError,
                onDone: () {
                  unawaited(controller.close());
                },
              );
        },
        onCancel: () {
          unawaited(_subscription?.cancel());
          _subscription = null;
        },
      );
      _controller = controller;
      data = controller.stream;
    }
  }

  Future<void> setValue(int value) async {
    if (type != BLEServiceType.setInt || qualifiedCharacteristic == null) {
      throw StateError('Writable characteristic is not connected');
    }
    if (value < 0 || value > 255) throw RangeError.range(value, 0, 255);
    await _ble
        .writeCharacteristicWithResponse(
          qualifiedCharacteristic!,
          value: [value],
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<void> dispose() async {
    qualifiedCharacteristic = null;
    await _subscription?.cancel();
    _subscription = null;
    // Do not await close: a paused downstream listener may not drain until its
    // widget resumes. Native cancellation above has already completed.
    unawaited(_controller?.close());
    _controller = null;
    data = null;
  }
}
