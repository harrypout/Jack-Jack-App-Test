import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/main.dart' as app;
import 'package:jackjack/services/background_service_manager.dart';
import 'package:jackjack/services/notification_history.dart';
import 'package:jackjack/utils/env_manager.dart';
import '../providers/connection_integration_test.dart' show GattClient;
import '../support/app_test_harness.dart';

class WorkerInstance implements ServiceInstance {
  final channels = <String, StreamController<Map<String, dynamic>?>>{};
  final events = <(String, Map<String, dynamic>?)>[];
  bool stopped = false;
  @override
  Stream<Map<String, dynamic>?> on(String method) =>
      channels.putIfAbsent(method, () => StreamController.broadcast()).stream;
  @override
  void invoke(String method, [Map<String, dynamic>? args]) {
    events.add((method, args));
  }

  @override
  Future<void> stopSelf() async {
    stopped = true;
  }

  void command(
    String command,
    String request, {
    List<String> ids = const [deviceA],
  }) => channels['monitorCommand']!.add({
    'command': command,
    'requestId': request,
    'deviceIds': ids,
    'deviceNames': {deviceA: 'Nursery'},
  });
  bool ack(String request) => events.any(
    (e) =>
        e.$1 == 'monitorAck' &&
        e.$2?['requestId'] == request &&
        e.$2?['error'] == null,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

void main() {
  final harness = AppTestHarness()..install();
  setUpAll(() async {
    dotenv.testLoad(
      fileInput: File('test/fixtures/ble.env').readAsStringSync(),
    );
    await EnvManager.getInstance();
  });
  Future<(WorkerInstance, GattClient)> start() async {
    final worker = WorkerInstance();
    final ble = GattClient();
    await BackgroundServiceManager.runWorker(
      worker,
      preferences: app.prefs,
      ble: ble,
    );
    addTearDown(() async {
      worker.channels['stopService']!.add({});
      await harness.flushEvents();
    });
    worker.command('acquire', 'start');
    await harness.flushEvents();
    expect(worker.ack('start'), true);
    expect(ble.sessions, hasLength(1));
    ble.emit(DeviceConnectionState.connected);
    await harness.flushEvents();
    return (worker, ble);
  }

  test(
    'JJ-01: background worker delivers and persists alerts without foreground listeners',
    () async {
      final (worker, ble) = await start();
      ble.packets[configs.thresholdAlertUUIDS.characteristic]!.add([1]);
      await harness.flushEvents();
      expect(harness.shownNotifications, hasLength(1));
      expect(NotificationHistory.read(app.prefs).single.deviceId, deviceA);
      expect(
        worker.events.any(
          (e) => e.$1 == 'thresholdAlert' && e.$2?['handled'] == true,
        ),
        true,
      );
    },
  );
  test(
    'JJ-01: repeated handoff requests are idempotent and release acknowledges after cancellation',
    () async {
      final (worker, ble) = await start();
      worker.command('acquire', 'start');
      worker.command('acquire', 'next');
      await harness.flushEvents();
      expect(ble.sessions, hasLength(1));
      worker.command('release', 'release');
      await harness.flushEvents();
      expect(worker.ack('release'), true);
      expect(ble.cancellations, 1);
      expect(ble.packets.values.where((c) => c.hasListener), isEmpty);
      expect(ble.statuses.hasListener, false);
    },
  );
  test(
    'JJ-03: forgetting a device also cancels the background owner',
    () async {
      final (worker, ble) = await start();
      worker.channels['forgetDevice']!.add({'deviceId': deviceA});
      await harness.flushEvents();
      expect(ble.cancellations, 1);
      ble.packets[configs.thresholdAlertUUIDS.characteristic]!.add([1]);
      await harness.flushEvents();
      expect(harness.shownNotifications, isEmpty);
      expect(NotificationHistory.read(app.prefs), isEmpty);
      worker.command('acquire', 'again');
      await harness.flushEvents();
      expect(ble.sessions, hasLength(1));
    },
  );
  test(
    'JJ-01/JJ-10: Alerts off is enforced inside the background worker',
    () async {
      final (_, ble) = await start();
      await app.prefs.setBool('${deviceA}s', false);
      await app.prefs.setBool('${deviceA}v', false);
      ble.packets[configs.thresholdAlertUUIDS.characteristic]!.add([1]);
      await harness.flushEvents();
      expect(harness.shownNotifications, isEmpty);
      expect(NotificationHistory.read(app.prefs), hasLength(1));
    },
  );
  test(
    'JJ-02: background reconnect creates fresh GATT subscriptions and delivers the next alert',
    () async {
      final (worker, ble) = await start();
      ble.emit(DeviceConnectionState.disconnected);
      await harness.flushEvents();
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(ble.sessions, hasLength(2));
      ble.emit(DeviceConnectionState.connected);
      await harness.flushEvents();
      expect(
        ble.subscriptions.where(
          (id) => id == configs.thresholdAlertUUIDS.characteristic,
        ),
        hasLength(2),
      );
      ble.packets[configs.thresholdAlertUUIDS.characteristic]!.add([1]);
      await harness.flushEvents();
      expect(NotificationHistory.read(app.prefs).single.deviceId, deviceA);
      final bodies = harness.shownNotifications.map((n) => n['body']);
      expect(bodies, contains('Nursery was disconnected'));
      expect(bodies, contains('Nursery was connected'));
      worker.command('release', 'finish');
      await harness.flushEvents();
      expect(worker.ack('finish'), true);
    },
  );
}
