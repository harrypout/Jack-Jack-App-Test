import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/main.dart' as app;
import 'package:jackjack/services/alert_recorder.dart';
import 'package:jackjack/services/notification_history.dart';
import '../support/app_test_harness.dart';

void main() {
  final harness = AppTestHarness()..install();
  test(
    'JJ-06: one warning below 20%, rearmed at 25%, survives recreation',
    () async {
      var recorder = AlertRecorder(app.prefs);
      expect(await recorder.battery(deviceA, 'Nursery', 20), isNull);
      expect((await recorder.battery(deviceA, 'Nursery', 19))?.value, 19);
      recorder = AlertRecorder(app.prefs);
      for (final level in [18, 21, 24, 19]) {
        expect(await recorder.battery(deviceA, 'Nursery', level), isNull);
      }
      expect(await recorder.battery(deviceA, 'Nursery', 25), isNull);
      expect(await recorder.battery(deviceA, 'Nursery', 19), isNotNull);
      expect(harness.shownNotifications, hasLength(2));
      expect(NotificationHistory.read(app.prefs).map((event) => event.kind), [
        'battery',
        'battery',
      ]);
    },
  );
  test(
    'JJ-06/JJ-10: disabled warnings retain history, devices have independent episodes',
    () async {
      await app.prefs.setBool('${deviceA}s', false);
      await app.prefs.setBool('${deviceA}v', false);
      final recorder = AlertRecorder(app.prefs);
      await recorder.battery(deviceA, 'Same name', 15);
      await recorder.battery(deviceB, 'Same name', 10);
      expect(harness.shownNotifications, hasLength(1));
      expect(
        NotificationHistory.read(app.prefs).map((e) => e.deviceId).toSet(),
        {deviceA, deviceB},
      );
    },
  );
  test(
    'JJ-06: invalid battery packets do not trigger or rearm an episode',
    () async {
      final recorder = AlertRecorder(app.prefs);
      await recorder.battery(deviceA, 'Nursery', 19);
      for (final level in [-1, 101, 255]) {
        expect(await recorder.battery(deviceA, 'Nursery', level), isNull);
      }
      expect(await recorder.battery(deviceA, 'Nursery', 18), isNull);
      expect(harness.shownNotifications, hasLength(1));
    },
  );
  test(
    'JJ-01: service records and notifies with no provider or UI subscriber',
    () async {
      final recorder = AlertRecorder(app.prefs, now: () => harness.now);
      await recorder.sound(deviceA, 'Nursery', 1);
      expect(harness.shownNotifications, hasLength(1));
      expect(NotificationHistory.read(app.prefs).single.deviceId, deviceA);
      final reopened = AlertRecorder(app.prefs, now: () => harness.now);
      expect(await reopened.sound(deviceA, 'Nursery', 1), isNull);
      expect(harness.shownNotifications, hasLength(1));
    },
  );
  test(
    'JJ-01: concurrent positive packets record one event and use the saved name',
    () async {
      await app.prefs.setString('device_names', '{"$deviceA":"Jack’s room"}');
      final recorder = AlertRecorder(app.prefs, now: () => harness.now);
      await Future.wait(
        List.generate(10, (_) => recorder.sound(deviceA, 'Mic Sense', 1)),
      );
      expect(NotificationHistory.read(app.prefs).single.device, 'Jack’s room');
      expect(harness.shownNotifications, hasLength(1));
    },
  );
  test(
    'JJ-03: forgotten devices are rejected by an independent service recorder',
    () async {
      await app.prefs.setBool('forgotten_$deviceA', true);
      final recorder = AlertRecorder(app.prefs);
      expect(await recorder.sound(deviceA, 'Nursery', 1), isNull);
      expect(await recorder.battery(deviceA, 'Nursery', 5), isNull);
      expect(harness.shownNotifications, isEmpty);
      expect(NotificationHistory.read(app.prefs), isEmpty);
    },
  );
  test('clock rollback does not silence a device indefinitely', () async {
    final recorder = AlertRecorder(app.prefs, now: () => harness.now);
    await recorder.sound(deviceA, 'Nursery', 1);
    harness.now = harness.now.subtract(const Duration(hours: 1));
    expect(await recorder.sound(deviceA, 'Nursery', 1), isNotNull);
    expect(harness.shownNotifications, hasLength(2));
  });
}
