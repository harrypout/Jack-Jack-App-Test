import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/main.dart' as app;
import 'package:jackjack/utils/notification_manager.dart';
import '../support/app_test_harness.dart';

void main() {
  final harness = AppTestHarness()..install();
  Future<void> alert(String device) => NotificationManager.instance
      .showThresholdAlert(deviceId: device, deviceName: device, threshold: 1);

  for (final result in [false, null]) {
    test('Android still reports initialization failure for $result', () async {
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      harness.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (_) async => result,
      );
      await expectLater(
        NotificationManager.instance.initializePlugin(),
        result == null ? throwsA(isA<TypeError>()) : throwsStateError,
      );
    });
  }

  test(
    'rapid alerts get distinct IDs and cannot overwrite the background-service ID',
    () async {
      await alert(deviceA);
      await alert(deviceB);
      final ids = harness.shownNotifications.map((n) => n['id']).toList();
      expect(ids, hasLength(2));
      expect(ids.toSet(), hasLength(2));
      expect(ids, isNot(contains(888)));
    },
  );
  test('iOS alert uses the configured sound file and device name', () async {
    await app.prefs.setString('thresholdSound', 'Ping');
    await alert(deviceA);
    final notification = harness.shownNotifications.single;
    final details = notification['platformSpecifics'] as Map;
    expect(notification['body'], contains(deviceA));
    expect(details['presentAlert'], isTrue);
    expect(details['presentSound'], isTrue);
    expect(details['sound'], 'ping.mp3');
  });
  test(
    'one disabled device does not suppress another device’s alert',
    () async {
      await app.prefs.setBool('${deviceA}s', false);
      await app.prefs.setBool('${deviceA}v', false);
      await alert(deviceB);
      expect(harness.shownNotifications, hasLength(1));
      final details =
          harness.shownNotifications.single['platformSpecifics'] as Map;
      expect(details['presentSound'], isTrue);
    },
  );
  test(
    'Android notification keeps its configured sound and vibration channel',
    () async {
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await app.prefs.setString('thresholdSound', 'Ping');
      await alert(deviceA);
      final details =
          harness.shownNotifications.single['platformSpecifics'] as Map;
      expect(details['channelId'], 'alerts_channel_ping_vibration');
      expect(details['playSound'], isTrue);
      expect(details['enableVibration'], isTrue);
    },
  );
}
