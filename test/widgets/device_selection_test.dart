import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/main.dart' as app;
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/providers/selected_device_provider.dart';
import 'package:jackjack/screens/home/home_screen.dart';
import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:jackjack/services/app_initializer.dart';
import 'package:jackjack/widgets/ble_toggle_row.dart';
import '../support/app_test_harness.dart';

class ReadyInitializer extends AppInitializer {
  @override
  Future<InitPhase> build() async => InitPhase.complete;
}

class ReadyBluetooth extends BleStatusNotifier {
  @override
  BleStatus build() => BleStatus.ready;
}

class ReadyDevices extends ConnectedDevicesTracker {
  @override
  FutureOr<Set<String>> build() => {deviceA, deviceB};
}

void main() {
  AppTestHarness().install();
  Future<(ProviderContainer, FakeConnectedDevices)> home(
    WidgetTester tester,
  ) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final devices = FakeConnectedDevices({
      deviceA: testDevice(name: 'Nursery'),
      deviceB: testDevice(id: deviceB, name: 'Travel cot'),
    });
    final container = ProviderContainer(
      overrides: [
        connectedDevicesProvider.overrideWith(() => devices),
        connectedDevicesTrackerProvider.overrideWith(ReadyDevices.new),
        bleStatusNotifierProvider.overrideWith(ReadyBluetooth.new),
        appInitializerProvider.overrideWith(ReadyInitializer.new),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(selectedDeviceProvider.notifier)
        .setSelectedDevice(deviceA);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return (container, devices);
  }

  testWidgets(
    'JJ-13: users can select a second connected Jack Jack from its device card',
    (tester) async {
      final (container, _) = await home(tester);
      await tester.ensureVisible(find.text('Travel cot'));
      await tester.tap(find.text('Travel cot'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Show on meter'));
      await tester.tap(find.text('Show on meter'));
      await tester.pumpAndSettle();
      expect(container.read(selectedDeviceProvider), deviceB);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets(
    'JJ-13: removing a preceding row preserves the other device’s Alerts setting',
    (tester) async {
      await app.prefs.setBool('${deviceB}s', false);
      await app.prefs.setBool('${deviceB}v', false);
      final (_, devices) = await home(tester);
      await tester.ensureVisible(find.text('Travel cot'));
      await tester.tap(find.text('Travel cot'));
      await tester.pumpAndSettle();
      devices.replace({deviceB: devices.initialDevices[deviceB]!});
      await tester.pumpAndSettle();
      final alerts =
          tester
              .widgetList<BleToggleRow>(find.byType(BleToggleRow))
              .where((row) => row.data == 'Alerts')
              .toList();
      expect(alerts, hasLength(1));
      expect(alerts.single.value, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
