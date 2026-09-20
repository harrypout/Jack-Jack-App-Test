import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/main.dart' as app;
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/providers/selected_device_provider.dart';
import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:jackjack/services/device_services.dart';
import 'package:jackjack/utils/env_manager.dart';
import '../support/app_test_harness.dart';
import '../services/connection_test.dart' show ConnectionClient;

class GattClient extends ConnectionClient {
  final packets = <String, StreamController<List<int>>>{};
  final subscriptions = <String>[];
  int battery = 75;
  @override
  Future<List<int>> readCharacteristic(
    QualifiedCharacteristic characteristic,
  ) async {
    if (readError != null) throw readError!;
    return characteristic.characteristicId.toString() ==
            configs.getBatteryUUIDS.characteristic
        ? [battery]
        : readBytes;
  }

  @override
  Stream<List<int>> subscribeToCharacteristic(
    QualifiedCharacteristic characteristic,
  ) {
    final id = characteristic.characteristicId.toString();
    subscriptions.add(id);
    return packets.putIfAbsent(id, () => StreamController.broadcast()).stream;
  }
}

void main() {
  final harness = AppTestHarness()..install();
  setUpAll(() async {
    dotenv.testLoad(
      fileInput: File('test/fixtures/ble.env').readAsStringSync(),
    );
    await EnvManager.getInstance();
  });
  Future<(ProviderContainer, GattClient)> connected() async {
    final ble = GattClient();
    final container = ProviderContainer(
      overrides: [bleClientProvider.overrideWithValue(ble)],
    );
    addTearDown(container.dispose);
    container.read(selectedDeviceProvider);
    final request = container
        .read(connectedDevicesProvider.notifier)
        .connect(testDevice().device);
    await harness.flushEvents();
    ble.emit(DeviceConnectionState.connected);
    expect(
      await request,
      true,
      reason: container.read(connectionErrorProvider(deviceA)),
    );
    await harness.flushEvents();
    return (container, ble);
  }

  test(
    'JJ-02: provider owns one connection and supplies live alert and meter subscriptions',
    () async {
      final (container, ble) = await connected();
      expect(ble.sessions, hasLength(1));
      expect(container.read(connectedDevicesTrackerProvider).value, {deviceA});
      final forbidden = configs.getSoundUUIDS.characteristic;
      expect(ble.subscriptions, isNot(contains(forbidden)));
      expect(ble.subscriptions.toSet(), {
        configs.thresholdAlertUUIDS.characteristic,
        configs.getSoundLevelUUIDS.characteristic,
      });
      ble.packets[configs.thresholdAlertUUIDS.characteristic]!.add([1]);
      await harness.flushEvents();
      expect(harness.history(container).single.deviceId, deviceA);
      expect(app.prefs.getStringList('pairedDevicesUUID'), [deviceA]);
      await container.read(connectedDevicesProvider.notifier).suspend();
      expect(ble.packets.values.where((s) => s.hasListener), isEmpty);
    },
  );
  test(
    'JJ-06: battery refresh publishes a new provider value and read failure shows unknown',
    () async {
      final (container, ble) = await connected();
      var changes = 0;
      container.listen(connectedDevicesProvider, (_, _) {
        changes++;
      });
      ble.battery = 18;
      await container
          .read(connectedDevicesProvider.notifier)
          .refreshBattery(deviceA);
      expect(changes, greaterThan(0));
      expect(
        container.read(connectedDevicesProvider)[deviceA]!.getBattery.data,
        18,
      );
      expect(
        harness.history(container).where((e) => e.kind == 'battery'),
        hasLength(1),
      );
      ble.readError = StateError('battery timeout');
      await container
          .read(connectedDevicesProvider.notifier)
          .refreshBattery(deviceA);
      expect(
        container.read(connectedDevicesProvider)[deviceA]!.getBattery.data,
        isNull,
      );
      await container.read(connectedDevicesProvider.notifier).suspend();
    },
  );
  test(
    'JJ-03: forget closes native subscriptions and late callbacks cannot restore the device',
    () async {
      final (container, ble) = await connected();
      await container
          .read(connectedDevicesProvider.notifier)
          .removeDevice(deviceA);
      ble.packets[configs.thresholdAlertUUIDS.characteristic]!.add([1]);
      await harness.flushEvents();
      expect(container.read(connectedDevicesProvider), isEmpty);
      expect(container.read(connectedDevicesTrackerProvider).value, isEmpty);
      expect(app.prefs.getStringList('pairedDevicesUUID'), isEmpty);
      expect(ble.packets.values.where((s) => s.hasListener), isEmpty);
      expect(harness.history(container), isEmpty);
      expect(container.read(selectedDeviceProvider), isNull);
    },
  );
  test(
    'JJ-03: forgetting during placeholder construction cannot repopulate the registry',
    () async {
      final container = ProviderContainer(
        overrides: [bleClientProvider.overrideWithValue(GattClient())],
      );
      addTearDown(container.dispose);
      final notifier = container.read(connectedDevicesProvider.notifier);
      final loading = notifier.getServices(
        testDevice().device,
        shouldConnect: false,
      );
      await notifier.removeDevice(deviceA);
      await loading;
      expect(container.read(connectedDevicesProvider), isEmpty);
    },
  );
  test(
    'JJ-04: failed or out-of-range threshold reads never write to hardware',
    () async {
      for (final bytes in [
        [0],
        [255],
        <int>[],
      ]) {
        final ble = GattClient()..readBytes = bytes;
        await expectLater(
          DeviceServices.create(testDevice().device, ble),
          throwsA(anything),
        );
        expect(ble.writes, isEmpty);
      }
    },
  );
  test(
    'JJ-02: concurrent connect requests share the same native connection',
    () async {
      final ble = GattClient();
      final container = ProviderContainer(
        overrides: [bleClientProvider.overrideWithValue(ble)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(connectedDevicesProvider.notifier);
      final a = notifier.connect(testDevice().device);
      final b = notifier.connect(testDevice().device);
      await harness.flushEvents();
      expect(ble.sessions, hasLength(1));
      ble.emit(DeviceConnectionState.connected);
      expect(
        await a,
        true,
        reason: container.read(connectionErrorProvider(deviceA)),
      );
      expect(await b, true);
      await notifier.suspend();
    },
  );
  test(
    'JJ-02: resuming does not auto-connect a device that was only registered for display',
    () async {
      final ble = GattClient();
      final container = ProviderContainer(
        overrides: [bleClientProvider.overrideWithValue(ble)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(connectedDevicesProvider.notifier);
      await notifier.getServices(testDevice().device, shouldConnect: false);
      await notifier.resume();
      await harness.flushEvents();
      expect(ble.sessions, isEmpty);
      expect(notifier.desiredDevices, isEmpty);
    },
  );
  test(
    'JJ-03: disconnecting during a pending connect preserves the disabled preference',
    () async {
      final ble = GattClient();
      final container = ProviderContainer(
        overrides: [bleClientProvider.overrideWithValue(ble)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(connectedDevicesProvider.notifier);
      final pending = notifier.connect(testDevice().device);
      await notifier.connect(testDevice().device, shouldConnect: false);
      expect(await pending, false);
      expect(app.prefs.getBool('user_disconnected_$deviceA'), true);
      expect(container.read(connectionDesiredProvider(deviceA)), false);
      expect(ble.sessions, isEmpty);
      await notifier.resume();
      await harness.flushEvents();
      expect(ble.sessions, isEmpty);
    },
  );
}
