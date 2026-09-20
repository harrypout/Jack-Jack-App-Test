import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/main.dart' as app;
import 'package:jackjack/models/notification_sf.dart';
import 'package:jackjack/providers/notifications_provider.dart';
import '../support/app_test_harness.dart';

void main() {
  final harness = AppTestHarness()..install();
  NotificationSF event(String id, {DateTime? time}) =>
      NotificationSF(id: id, device: 'Nursery', value: 1, createdAt: time);

  test('history starts empty on a new installation', () {
    expect(harness.history(harness.container()), isEmpty);
  });
  test('saved events survive provider recreation and appear newest first', () {
    final first = harness.container();
    first.read(notificationsProvider.notifier).addNotification(event('older'));
    first.read(notificationsProvider.notifier).addNotification(event('newer'));
    expect(harness.history(first).map((e) => e.id), ['newer', 'older']);
    final reopened = harness.container();
    expect(harness.history(reopened).map((e) => e.id), ['newer', 'older']);
  });
  test(
    'clear history removes persisted events without removing device settings',
    () async {
      await app.prefs.setStringList('pairedDevicesUUID', [deviceA]);
      final container = harness.container();
      container
          .read(notificationsProvider.notifier)
          .addNotification(event('one'));
      container.read(notificationsProvider.notifier).clearAll();
      expect(harness.history(container), isEmpty);
      expect(harness.history(harness.container()), isEmpty);
      expect(app.prefs.getStringList('pairedDevicesUUID'), [deviceA]);
    },
  );
  test(
    'event serialization preserves ID, unicode device name and timestamp',
    () {
      final original = NotificationSF(
        id: 'event-123',
        device: 'Jack’s room 💤',
        value: 1,
        createdAt: DateTime.utc(2026, 9, 13, 10, 20, 30),
      );
      final restored = NotificationSF.fromString(original.toString());
      expect(restored.toJson(), original.toJson());
    },
  );
  test('legacy records without a timestamp can still be read', () {
    final record = NotificationSF.fromJson({
      'id': 'old',
      'device': 'Pebble',
      'value': 1,
    });
    expect(record.id, 'old');
    expect(record.device, 'Pebble');
    expect(record.createdAt, isA<DateTime>());
  });
  test('JJ-14: one malformed record does not hide valid history', () async {
    await app.prefs.setStringList('notifications', [
      event('first').toString(),
      'not valid JSON',
      event('last').toString(),
    ]);
    expect(harness.history(harness.container()).map((e) => e.id), [
      'last',
      'first',
    ]);
  });
  test('JJ-14: history retains at most the newest 1000 records', () async {
    await app.prefs.setStringList('notifications', [
      for (var i = 0; i < 1000; i++) event('event-$i').toString(),
    ]);
    final container = harness.container();
    container
        .read(notificationsProvider.notifier)
        .addNotification(event('newest'));
    final records = harness.history(container);
    expect(records, hasLength(1000));
    expect(records.first.id, 'newest');
    expect(records.any((e) => e.id == 'event-0'), isFalse);
    expect(app.prefs.getStringList('notifications'), hasLength(1000));
  });
  test(
    'JJ-14: history older than 30 days is removed while recent events remain',
    () async {
      final now = DateTime.now();
      await app.prefs.setStringList('notifications', [
        event(
          'expired',
          time: now.subtract(const Duration(days: 35)),
        ).toString(),
        event('recent', time: now.subtract(const Duration(days: 1))).toString(),
      ]);
      final container = harness.container();
      container
          .read(notificationsProvider.notifier)
          .addNotification(event('new'));
      expect(harness.history(container).map((e) => e.id), ['new', 'recent']);
      expect(app.prefs.getStringList('notifications'), hasLength(2));
    },
  );
}
