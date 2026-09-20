import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/models/ble_service.dart';
import 'package:jackjack/models/ble_uuids.dart';
import '../support/app_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeBleClient client;
  BLEService service(BLEServiceType type, {String name = 'GET_THRESHOLD'}) =>
      BLEService(
        deviceId: deviceA,
        type: type,
        client: client,
        data: 75,
        uuid: BLEUUIDS(
          name: name,
          service: testServiceId,
          characteristic: testCharacteristicId,
        ),
        qualifiedCharacteristic: QualifiedCharacteristic(
          deviceId: deviceA,
          serviceId: Uuid.parse(testServiceId),
          characteristicId: Uuid.parse(testCharacteristicId),
        ),
      );
  setUp(() {
    client = FakeBleClient();
  });
  tearDown(() async {
    await client.notifications.close();
  });

  test('one-byte threshold and battery values are read from BLE', () async {
    for (final value in [0, 20, 75, 100, 120]) {
      client.readBytes = [value];
      final read = service(BLEServiceType.getInt);
      await read.getValue();
      expect(read.data, value);
    }
  });
  test(
    'threshold writes target the correct characteristic and use one byte',
    () async {
      await service(BLEServiceType.setInt).setValue(90);
      expect(client.writes.single.$1.deviceId, deviceA);
      expect(
        client.writes.single.$1.characteristicId,
        Uuid.parse(testCharacteristicId),
      );
      expect(client.writes.single.$2, [90]);
    },
  );
  test('write failures are observable by the caller', () async {
    client.writeError = StateError('BLE write rejected');
    await expectLater(
      service(BLEServiceType.setInt).setValue(90),
      throwsStateError,
    );
  });
  test(
    'zero/reset and positive alert packets are forwarded in order',
    () async {
      final alert = service(BLEServiceType.stream, name: 'THRESHOLD_ALERT');
      await alert.getValue();
      final result = expectLater(
        alert.data as Stream<int>,
        emitsInOrder([0, 1, 0]),
      );
      client.notifications.add([0]);
      client.notifications.add([1]);
      client.notifications.add([0]);
      await result;
    },
  );
  test(
    'normal 75 dB two-byte packets currently retain the correct numeric value',
    () async {
      final sound = service(BLEServiceType.stream, name: 'GET_SOUND_LEVEL');
      await sound.getValue();
      final result = expectLater(sound.data as Stream<int>, emits(75));
      client.notifications.add([0x4b, 0x00]);
      await result;
    },
  );
  test('JJ-07: sound-level packets preserve signed 16-bit values', () async {
    final sound = service(BLEServiceType.stream, name: 'GET_SOUND_LEVEL');
    await sound.getValue();
    final result = expectLater(
      sound.data as Stream<int>,
      emitsInOrder([-1, 256]),
    );
    client.notifications.add([0xff, 0xff]);
    client.notifications.add([0x00, 0x01]);
    await result;
  });
  test(
    'JJ-04: a failed BLE read cannot become a fabricated zero measurement',
    () async {
      client.readError = StateError('read timed out');
      final read = service(BLEServiceType.getInt);
      await expectLater(read.getValue(), throwsStateError);
      expect(read.data, 75);
    },
  );
}
