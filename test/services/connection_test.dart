import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/services/device_connection.dart';
import '../support/app_test_harness.dart';

class ConnectionClient extends FakeBleClient {
  BleStatus currentStatus = BleStatus.ready;
  final statuses = StreamController<BleStatus>.broadcast();
  final sessions = <StreamController<ConnectionStateUpdate>>[];
  int cancellations = 0;
  @override
  BleStatus get status => currentStatus;
  @override
  Stream<BleStatus> get statusStream => statuses.stream;
  @override
  Stream<ConnectionStateUpdate> connectToDevice({
    required String id,
    Map<Uuid, List<Uuid>>? servicesWithCharacteristicsToDiscover,
    Duration? connectionTimeout,
  }) {
    final controller = StreamController<ConnectionStateUpdate>(
      onCancel: () {
        cancellations++;
        return Future<void>.value();
      },
    );
    sessions.add(controller);
    return controller.stream;
  }

  void emit(DeviceConnectionState state) => sessions.last.add(
    ConnectionStateUpdate(
      deviceId: deviceA,
      connectionState: state,
      failure: null,
    ),
  );
  void power(BleStatus status) {
    currentStatus = status;
    statuses.add(status);
  }
}

void main() {
  test('JJ-02: every disconnect creates and initializes a fresh connection', () {
    fakeAsync((clock) {
      final ble = ConnectionClient();
      var initializes = 0;
      var releases = 0;
      final phases = <ConnectionPhase>[];
      final connection = DeviceConnection(
        ble: ble,
        id: deviceA,
        initialize: (_) async {
          initializes++;
        },
        release: () async {
          releases++;
        },
        onPhase: (p, _) => phases.add(p),
      );
      unawaited(connection.start());
      clock.flushMicrotasks();
      for (var i = 0; i < 4; i++) {
        ble.emit(DeviceConnectionState.connected);
        clock.flushMicrotasks();
        expect(
          phases.last,
          ConnectionPhase.monitoring,
          reason:
              'Iteration $i; initialized $initializes; phases $phases; sessions ${ble.sessions.length}; releases $releases',
        );
        expect(initializes, i + 1);
        ble.emit(DeviceConnectionState.disconnected);
        clock.flushMicrotasks();
        expect(phases.last, ConnectionPhase.retrying);
        clock.elapse(const Duration(seconds: 2));
        clock.flushMicrotasks();
      }
      expect(ble.sessions, hasLength(5));
      expect(ble.cancellations, 4);
      expect(releases, 4);
      unawaited(connection.stop());
      clock.flushMicrotasks();
      expect(ble.statuses.hasListener, isFalse);
      expect(clock.nonPeriodicTimerCount, 0);
    });
  });
  test('JJ-03: stopping during backoff prevents future connections', () {
    fakeAsync((clock) {
      final ble = ConnectionClient();
      final connection = DeviceConnection(
        ble: ble,
        id: deviceA,
        initialize: (_) async {},
        release: () async {},
        onPhase: (_, _) {},
      );
      unawaited(connection.start());
      clock.flushMicrotasks();
      ble.sessions.last.addError(StateError('out of range'));
      clock.flushMicrotasks();
      unawaited(connection.stop());
      clock.flushMicrotasks();
      clock.elapse(const Duration(minutes: 10));
      expect(ble.sessions, hasLength(1));
      expect(ble.cancellations, 1);
      expect(clock.nonPeriodicTimerCount, 0);
    });
  });
  test('JJ-02: Bluetooth off waits and Bluetooth on reconnects once', () {
    fakeAsync((clock) {
      final ble = ConnectionClient()..currentStatus = BleStatus.poweredOff;
      final connection = DeviceConnection(
        ble: ble,
        id: deviceA,
        initialize: (_) async {},
        release: () async {},
        onPhase: (_, _) {},
      );
      unawaited(connection.start());
      clock.flushMicrotasks();
      clock.elapse(const Duration(minutes: 1));
      expect(ble.sessions, isEmpty);
      ble.power(BleStatus.ready);
      clock.flushMicrotasks();
      ble.power(BleStatus.ready);
      clock.flushMicrotasks();
      expect(ble.sessions, hasLength(1));
      unawaited(connection.stop());
      clock.flushMicrotasks();
    });
  });
  test('JJ-02: a hung native connection has a bounded timeout and retry', () {
    fakeAsync((clock) {
      final ble = ConnectionClient();
      final phases = <ConnectionPhase>[];
      final connection = DeviceConnection(
        ble: ble,
        id: deviceA,
        initialize: (_) async {},
        release: () async {},
        onPhase: (p, _) => phases.add(p),
      );
      bool? first;
      connection.start().then((value) => first = value);
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 20));
      clock.flushMicrotasks();
      expect(first, false);
      expect(phases.last, ConnectionPhase.retrying);
      clock.elapse(const Duration(seconds: 2));
      clock.flushMicrotasks();
      expect(ble.sessions, hasLength(2));
      unawaited(connection.stop());
      clock.flushMicrotasks();
    });
  });
  test('JJ-03: late GATT setup cannot mark a stopped session ready', () {
    fakeAsync((clock) {
      final ble = ConnectionClient();
      final gate = Completer<void>();
      final phases = <ConnectionPhase>[];
      bool? current;
      final connection = DeviceConnection(
        ble: ble,
        id: deviceA,
        initialize: (isCurrent) async {
          await gate.future;
          current = isCurrent();
        },
        release: () async {},
        onPhase: (p, _) => phases.add(p),
      );
      unawaited(connection.start());
      clock.flushMicrotasks();
      ble.emit(DeviceConnectionState.connected);
      clock.flushMicrotasks();
      unawaited(connection.stop());
      clock.flushMicrotasks();
      gate.complete();
      clock.flushMicrotasks();
      expect(current, false);
      expect(phases, isNot(contains(ConnectionPhase.monitoring)));
      expect(clock.nonPeriodicTimerCount, 0);
    });
  });
  test(
    'JJ-02: stream completion retries, and a failed setup never claims monitoring',
    () {
      fakeAsync((clock) {
        final ble = ConnectionClient();
        final phases = <ConnectionPhase>[];
        final connection = DeviceConnection(
          ble: ble,
          id: deviceA,
          initialize: (_) async {
            throw StateError('missing characteristic');
          },
          release: () async {},
          onPhase: (p, _) => phases.add(p),
        );
        unawaited(connection.start());
        clock.flushMicrotasks();
        ble.emit(DeviceConnectionState.connected);
        clock.flushMicrotasks();
        expect(phases.last, ConnectionPhase.retrying);
        expect(phases, isNot(contains(ConnectionPhase.monitoring)));
        clock.elapse(const Duration(seconds: 2));
        clock.flushMicrotasks();
        unawaited(ble.sessions.last.close());
        clock.flushMicrotasks();
        expect(phases.last, ConnectionPhase.retrying);
        unawaited(connection.stop());
        clock.flushMicrotasks();
      });
    },
  );
}
