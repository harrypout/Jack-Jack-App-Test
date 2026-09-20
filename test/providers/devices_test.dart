import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/main.dart' as app;
import 'package:jackjack/providers/paired_devices.dart';
import 'package:jackjack/providers/selected_device_provider.dart';
import 'package:jackjack/services/device_name_manager.dart';
import '../support/app_test_harness.dart';

void main() {
  final harness = AppTestHarness()..install();

  test(
    'pairing the same ID twice persists one entry and survives cache reload',
    () async {
      await PairedDevicesUUID.saveToPrefs(deviceA);
      await PairedDevicesUUID.saveToPrefs(deviceA);
      await PairedDevicesUUID.saveToPrefs(deviceB);
      PairedDevicesUUID.list = [];
      await PairedDevicesUUID.loadFromPrefs();
      expect(PairedDevicesUUID.getList, [deviceA, deviceB]);
      expect(app.prefs.getStringList('pairedDevicesUUID'), [deviceA, deviceB]);
    },
  );
  test('forgetting a paired ID preserves other paired IDs', () async {
    await PairedDevicesUUID.saveToPrefs(deviceA);
    await PairedDevicesUUID.saveToPrefs(deviceB);
    await PairedDevicesUUID.removeFromPrefs(deviceA);
    await PairedDevicesUUID.loadFromPrefs();
    expect(PairedDevicesUUID.getList, [deviceB]);
  });
  test(
    'assigned names remain associated with IDs across rename, reload and removal',
    () async {
      final names = DeviceNameManager.instance;
      await names.setDeviceName(deviceA, 'Jack’s room');
      await names.setDeviceName(deviceB, 'Travel cot');
      await names.setDeviceName(deviceA, 'Nursery');
      await names.initialize();
      expect(names.getDisplayName(deviceA, 'Mic-Sense'), 'Nursery');
      await names.removeDeviceName(deviceA);
      expect(names.getDisplayName(deviceA, 'Mic-Sense'), 'Mic-Sense');
      expect(names.getDisplayName(deviceB, 'Mic-Sense'), 'Travel cot');
    },
  );
  test('malformed saved device names use advertised-name fallback', () async {
    await app.prefs.setString('device_names', '{bad json');
    expect(
      DeviceNameManager.instance.getDisplayName(deviceA, 'Mic-Sense'),
      'Mic-Sense',
    );
  });
  test(
    'switching selection stops the old gauge stream and enables the new one',
    () async {
      final switchA = FakeService();
      final switchB = FakeService();
      final container = harness.container(
        connected: FakeConnectedDevices({
          deviceA: testDevice(soundSwitch: switchA),
          deviceB: testDevice(id: deviceB, soundSwitch: switchB),
        }),
      );
      final selected = container.read(selectedDeviceProvider.notifier);
      await selected.setSelectedDevice(deviceA);
      await selected.setSelectedDevice(deviceB);
      expect(switchA.writes, [1, 0]);
      expect(switchB.writes, [1]);
      expect(container.read(selectedDeviceProvider), deviceB);
    },
  );
}
