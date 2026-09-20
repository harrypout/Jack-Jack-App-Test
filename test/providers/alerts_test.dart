import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/main.dart' as app;
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/providers/threshold_alert_provider.dart';
import 'package:jackjack/providers/last_recorded_alert_provider.dart';
import '../support/app_test_harness.dart';

void main() {
  final harness = AppTestHarness()..install();

  test(
    'foreground alert produces one phone notification and one history event',
    () async {
      final input = StreamController<int>.broadcast();
      addTearDown(input.close);
      final container = harness.container(
        connected: FakeConnectedDevices({
          deviceA: testDevice(name: 'Nursery', alerts: input.stream),
        }),
      );
      container.read(thresholdAlertProvider.notifier).setupDeviceAlert(deviceA);
      input.add(1);
      await harness.flushEvents();
      expect(harness.shownNotifications, hasLength(1));
      expect(harness.shownNotifications.single['body'], contains('Nursery'));
      expect(harness.history(container), hasLength(1));
      expect(app.prefs.getStringList('notifications'), hasLength(1));
    },
  );

  test('zero events neither notify nor delay the first real alert', () async {
    final container = harness.container();
    container.read(thresholdAlertProvider);
    harness.background.alert(deviceA, value: 0);
    await harness.flushEvents();
    expect(harness.shownNotifications, isEmpty);
    expect(harness.history(container), isEmpty);
    harness.background.alert(deviceA);
    await harness.flushEvents();
    expect(harness.shownNotifications, hasLength(1));
  });

  test(
    'cooldown suppresses repeats before 15 seconds and accepts the boundary',
    () async {
      final container = harness.container();
      container.read(thresholdAlertProvider);
      harness.background.alert(deviceA);
      await harness.flushEvents();
      harness.now = harness.now.add(const Duration(milliseconds: 14999));
      harness.background.alert(deviceA);
      await harness.flushEvents();
      expect(harness.history(container), hasLength(1));
      harness.now = harness.now.add(const Duration(milliseconds: 1));
      harness.background.alert(deviceA);
      await harness.flushEvents();
      expect(harness.history(container), hasLength(2));
      expect(harness.shownNotifications, hasLength(2));
    },
  );

  test(
    'each Pebble has its own cooldown even when advertised names match',
    () async {
      final container = harness.container();
      container.read(thresholdAlertProvider);
      harness.background.alert(deviceA, name: 'Mic-Sense');
      harness.background.alert(deviceB, name: 'Mic-Sense');
      harness.background.alert(deviceA, name: 'Mic-Sense');
      await harness.flushEvents();
      expect(harness.shownNotifications, hasLength(2));
      expect(harness.history(container), hasLength(2));
    },
  );

  test(
    'foreground/background overlap cannot double-notify for one device',
    () async {
      final input = StreamController<int>.broadcast();
      addTearDown(input.close);
      final container = harness.container(
        connected: FakeConnectedDevices({
          deviceA: testDevice(alerts: input.stream),
        }),
      );
      container.read(thresholdAlertProvider.notifier).setupDeviceAlert(deviceA);
      input.add(1);
      await harness.flushEvents();
      harness.background.alert(deviceA);
      await harness.flushEvents();
      expect(harness.shownNotifications, hasLength(1));
      expect(harness.history(container), hasLength(1));
    },
  );

  test(
    'the selected repeat interval applies to a full firmware alert window',
    () async {
      await app.prefs.setString('notificationTimeout', '30 seconds');
      final container = harness.container();
      container.read(thresholdAlertProvider);
      final start = harness.now;
      for (var second = 0; second < 120; second += 3) {
        harness.now = start.add(Duration(seconds: second));
        harness.background.alert(deviceA);
        await harness.flushEvents();
      }
      expect(harness.history(container), hasLength(4));
      expect(harness.shownNotifications, hasLength(4));
    },
  );

  test('repeated setup does not duplicate user-visible alerts', () async {
    final input = StreamController<int>.broadcast();
    addTearDown(input.close);
    final container = harness.container(
      connected: FakeConnectedDevices({
        deviceA: testDevice(alerts: input.stream),
      }),
    );
    final alerts = container.read(thresholdAlertProvider.notifier);
    alerts.setupDeviceAlert(deviceA);
    alerts.setupDeviceAlert(deviceA);
    input.add(1);
    await harness.flushEvents();
    expect(harness.history(container), hasLength(1));
  });

  test(
    'fresh GATT streams deliver alerts after every simulated reconnection',
    () async {
      final connected = FakeConnectedDevices({});
      final container = harness.container(connected: connected);
      container.read(connectedDevicesProvider);
      final alerts = container.read(thresholdAlertProvider.notifier);
      for (var cycle = 0; cycle < 5; cycle++) {
        final input = StreamController<int>.broadcast();
        try {
          connected.replace({deviceA: testDevice(alerts: input.stream)});
          alerts.setupAlerts();
          input.add(1);
          await harness.flushEvents();
          expect(harness.history(container), hasLength(cycle + 1));
          expect(harness.shownNotifications, hasLength(cycle + 1));
        } finally {
          await input.close();
        }
        connected.replace({});
        alerts.setupAlerts();
        harness.now = harness.now.add(const Duration(seconds: 15));
      }
    },
  );

  test('setup for a missing device is a no-op', () async {
    final container = harness.container();
    container.read(thresholdAlertProvider.notifier).setupDeviceAlert(deviceA);
    await harness.flushEvents();
    expect(harness.shownNotifications, isEmpty);
    expect(harness.history(container), isEmpty);
  });

  test(
    'background connection events reach the phone notification boundary',
    () async {
      final container = harness.container();
      container.read(thresholdAlertProvider);
      harness.background.channels['deviceDisconnected']!.add({
        'deviceId': deviceA,
        'deviceName': 'Nursery',
      });
      harness.background.channels['deviceConnected']!.add({
        'deviceId': deviceA,
        'deviceName': 'Nursery',
      });
      await harness.flushEvents();
      expect(
        harness.shownNotifications.map((n) => n['body']),
        containsAll(['Nursery was disconnected', 'Nursery was connected']),
      );
      expect(harness.history(container), isEmpty);
    },
  );

  test('Alerts off keeps recording history', () async {
    await app.prefs.setBool('${deviceA}s', false);
    await app.prefs.setBool('${deviceA}v', false);
    final container = harness.container();
    container.read(thresholdAlertProvider);
    harness.background.alert(deviceA);
    await harness.flushEvents();
    expect(harness.history(container), hasLength(1));
  });

  test(
    'JJ-10: Alerts off suppresses phone notifications but preserves history',
    () async {
      await app.prefs.setBool('${deviceA}s', false);
      await app.prefs.setBool('${deviceA}v', false);
      final container = harness.container();
      container.read(thresholdAlertProvider);
      harness.background.alert(deviceA);
      await harness.flushEvents();
      expect(harness.history(container), hasLength(1));
      expect(harness.shownNotifications, isEmpty);
    },
  );

  test(
    'JJ-03: provider disposal releases all background channel listeners',
    () async {
      final container = harness.container();
      container.read(thresholdAlertProvider);
      expect(harness.background.channels, hasLength(3));
      container.dispose();
      await harness.flushEvents();
      expect(
        harness.background.channels.values.where((c) => c.hasListener),
        isEmpty,
      );
    },
  );

  test(
    'JJ-03: a removed device cannot crash or deliver further alerts',
    () async {
      final input = StreamController<int>.broadcast();
      addTearDown(input.close);
      final container = harness.container(
        connected: FakeConnectedDevices({
          deviceA: testDevice(alerts: input.stream),
        }),
      );
      final errors = <Object>[];
      runZonedGuarded(
        () {
          container
              .read(thresholdAlertProvider.notifier)
              .setupDeviceAlert(deviceA);
        },
        (error, stack) {
          errors.add(error);
        },
      );
      await container
          .read(connectedDevicesProvider.notifier)
          .removeDevice(deviceA);
      input.add(1);
      await harness.flushEvents();
      expect(errors, isEmpty);
      expect(harness.shownNotifications, isEmpty);
      expect(harness.history(container), isEmpty);
    },
  );
  test(
    'last recorded alert metadata is independent per stable device ID',
    () async {
      final container = harness.container();
      container.read(thresholdAlertProvider);
      expect(container.read(lastRecordedAlertProvider(deviceA)), isNull);
      final firstTime = harness.now;
      harness.background.alert(deviceA, name: 'Same name');
      await harness.flushEvents();
      harness.now = firstTime.add(const Duration(seconds: 3));
      harness.background.alert(deviceA, name: 'Same name');
      harness.background.alert(deviceB, name: 'Same name');
      await harness.flushEvents();
      expect(container.read(lastRecordedAlertProvider(deviceA)), firstTime);
      expect(container.read(lastRecordedAlertProvider(deviceB)), harness.now);
      expect(harness.history(container), hasLength(2));
      expect(harness.shownNotifications, hasLength(2));
    },
  );

  test(
    'foreground alert records a display timestamp and zero events do not erase it',
    () async {
      final input = StreamController<int>.broadcast();
      addTearDown(input.close);
      final container = harness.container(
        connected: FakeConnectedDevices({
          deviceA: testDevice(alerts: input.stream),
        }),
      );
      container.read(thresholdAlertProvider.notifier).setupDeviceAlert(deviceA);
      input.add(1);
      await harness.flushEvents();
      final recordedAt = harness.now;
      expect(container.read(lastRecordedAlertProvider(deviceA)), recordedAt);
      harness.now = recordedAt.add(const Duration(seconds: 15));
      input.add(0);
      await harness.flushEvents();
      expect(container.read(lastRecordedAlertProvider(deviceA)), recordedAt);
      expect(harness.history(container), hasLength(1));
    },
  );
}
