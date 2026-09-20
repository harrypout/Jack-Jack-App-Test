import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/main.dart' as app;
import 'package:jackjack/services/alert_recorder.dart';
import 'package:jackjack/services/device_name_manager.dart';
import 'package:jackjack/utils/device_display_name.dart';
import '../support/app_test_harness.dart';

void main() {
  final harness = AppTestHarness()..install();
  test(
    'legacy advertised names use Jack Jack and custom names remain recognizable',
    () {
      expect(displayDeviceName('Pebble'), 'Jack Jack');
      expect(displayDeviceName('PEBBLE 2'), 'Jack Jack 2');
      expect(displayDeviceName('Nursery'), 'Nursery');
      expect(displayDeviceName(''), 'Jack Jack');
    },
  );
  test(
    'saved legacy names use Jack Jack in history and phone alerts',
    () async {
      await DeviceNameManager.instance.setDeviceName(deviceA, 'Pebble 2');
      expect(
        DeviceNameManager.instance.getDisplayName(deviceA, 'Other'),
        'Jack Jack 2',
      );
      final recorder = AlertRecorder(app.prefs);
      final event = await recorder.sound(deviceA, 'Pebble', 1);
      expect(event!.device, 'Jack Jack 2');
      expect(
        harness.shownNotifications.single['body'],
        'Sound level exceeded on Jack Jack 2',
      );
      expect(event.deviceId, deviceA);
    },
  );
}
