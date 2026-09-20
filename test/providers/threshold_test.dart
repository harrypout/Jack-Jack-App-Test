import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/providers/device_threshold_provider.dart';
import '../support/app_test_harness.dart';

void main() {
  final harness = AppTestHarness()..install();

  test(
    'threshold starts with the device value; draft changes do not write BLE',
    () {
      final write = FakeService();
      final container = harness.container(
        connected: FakeConnectedDevices({
          deviceA: testDevice(read: FakeService(value: 55), write: write),
        }),
      );
      final provider = deviceThresholdProvider(deviceA);
      container.listen(provider, (_, _) {});
      expect(container.read(provider), 55);
      container.read(provider.notifier).change(90);
      expect(container.read(provider), 90);
      expect(write.writes, isEmpty);
    },
  );

  test('save waits for the write before reading the threshold back', () async {
    final gate = Completer<void>();
    final read = FakeService(value: 55, readBack: 90);
    final write = FakeService()..writeGate = gate;
    final container = harness.container(
      connected: FakeConnectedDevices({
        deviceA: testDevice(read: read, write: write),
      }),
    );
    final provider = deviceThresholdProvider(deviceA);
    container.listen(provider, (_, _) {});
    final saving = container.read(provider.notifier).saveToDevice(deviceA, 90);
    await harness.flushEvents(); // Allow the serialized write queue to start.
    expect(write.writes, [90]);
    expect(read.readCount, 0);
    expect(container.read(provider), 55);
    gate.complete();
    await saving;
    expect(read.readCount, 1);
    expect(container.read(provider), 90);
  });

  test(
    'threshold state and writes remain isolated between two Jack Jack devices',
    () async {
      final writeA = FakeService();
      final writeB = FakeService();
      final container = harness.container(
        connected: FakeConnectedDevices({
          deviceA: testDevice(
            read: FakeService(value: 55, readBack: 80),
            write: writeA,
          ),
          deviceB: testDevice(
            id: deviceB,
            read: FakeService(value: 65),
            write: writeB,
          ),
        }),
      );
      container.listen(deviceThresholdProvider(deviceA), (_, _) {});
      container.listen(deviceThresholdProvider(deviceB), (_, _) {});
      await container
          .read(deviceThresholdProvider(deviceA).notifier)
          .saveToDevice(deviceA, 80);
      expect(writeA.writes, [80]);
      expect(writeB.writes, isEmpty);
      expect(container.read(deviceThresholdProvider(deviceB)), 65);
    },
  );

  test(
    'JJ-04: device readback wins when it differs from the requested threshold',
    () async {
      final container = harness.container(
        connected: FakeConnectedDevices({
          deviceA: testDevice(read: FakeService(value: 55, readBack: 55)),
        }),
      );
      final provider = deviceThresholdProvider(deviceA);
      container.listen(provider, (_, _) {});
      await container.read(provider.notifier).saveToDevice(deviceA, 90);
      expect(container.read(provider), 55);
    },
  );

  test(
    'JJ-04: a missing device cannot report a successful threshold save',
    () async {
      final container = harness.container();
      final provider = deviceThresholdProvider(deviceA);
      container.listen(provider, (_, _) {});
      await expectLater(
        container.read(provider.notifier).saveToDevice(deviceA, 90),
        throwsA(isA<StateError>()),
      );
      expect(container.read(provider), isNull);
    },
  );

  test('JJ-04: failed writes restore the last confirmed threshold', () async {
    final container = harness.container(
      connected: FakeConnectedDevices({
        deviceA: testDevice(
          read: FakeService(value: 55),
          write: FakeService(
            writeError: StateError('disconnected during write'),
          ),
        ),
      }),
    );
    final provider = deviceThresholdProvider(deviceA);
    container.listen(provider, (_, _) {});
    final threshold = container.read(provider.notifier);
    threshold.change(90);
    await expectLater(threshold.saveToDevice(deviceA, 90), throwsStateError);
    expect(container.read(provider), 55);
  });
}
