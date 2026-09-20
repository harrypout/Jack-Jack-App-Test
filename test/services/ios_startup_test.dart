import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/screens/pairing/pods/available_devices.dart';
import 'package:jackjack/services/app_initializer.dart';
import 'package:jackjack/utils/env_manager.dart';
import 'package:jackjack/utils/notification_manager.dart';
import '../support/app_test_harness.dart';

class ScanningClient extends FakeBleClient {
  final discoveries = StreamController<DiscoveredDevice>.broadcast();
  final filters = <List<Uuid>>[];
  @override
  BleStatus get status => BleStatus.ready;
  @override
  Stream<BleStatus> get statusStream => const Stream.empty();
  @override
  Stream<DiscoveredDevice> scanForDevices({
    required List<Uuid> withServices,
    ScanMode scanMode = ScanMode.balanced,
    bool requireLocationServicesEnabled = true,
  }) {
    filters.add(withServices);
    return discoveries.stream;
  }
}

void main() {
  final harness = AppTestHarness()..install();
  const notificationChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  late List<bool> permissionRequests;
  Object? initializationError;

  setUpAll(() async {
    dotenv.testLoad(
      fileInput: File('test/fixtures/ble.env').readAsStringSync(),
    );
    await EnvManager.getInstance();
  });
  setUp(() {
    permissionRequests = [];
    initializationError = null;
    harness.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      notificationChannel,
      (call) async {
        harness.notificationCalls.add(call);
        if (call.method == 'initialize') {
          if (initializationError != null) throw initializationError!;
          // The real iOS plugin returns NO when no permissions are requested,
          // after configuring notification presentation and categories.
          return false;
        }
        return null;
      },
    );
  });

  (ProviderContainer, ScanningClient) startup({
    bool bluetoothGranted = true,
    bool notificationsGranted = true,
  }) {
    final ble = ScanningClient();
    final container = ProviderContainer(
      overrides: [
        bleClientProvider.overrideWithValue(ble),
        readinessChecksProvider.overrideWithValue(
          ReadinessChecks(
            bluetooth: (_) async => bluetoothGranted,
            notifications: (request) async {
              permissionRequests.add(request);
              return notificationsGranted;
            },
            initialize: NotificationManager.instance.initializePlugin,
          ),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await ble.discoveries.close();
    });
    container.read(deviceManagerProvider);
    return (container, ble);
  }

  Future<void> expectDiscovery(
    ProviderContainer container,
    ScanningClient ble,
  ) async {
    await harness.flushEvents();
    expect(ble.filters.last, [Uuid.parse(configs.setThresholdUUIDS.service)]);
    ble.discoveries.add(testDevice().device);
    await harness.flushEvents();
    expect(container.read(deviceManagerProvider).available.map((d) => d.id), [
      deviceA,
    ]);
  }

  for (final granted in [true, false]) {
    test(
      'iOS starts discovery with native initialize=false and notifications granted=$granted',
      () async {
        final (container, ble) = startup(notificationsGranted: granted);
        expect(
          await container.read(appInitializerProvider.future),
          granted ? InitPhase.complete : InitPhase.notificationsDenied,
        );
        expect(container.read(appInitializerProvider).hasError, false);
        expect(permissionRequests, [true]);
        await expectDiscovery(container, ble);
        final settings =
            harness.notificationCalls
                    .singleWhere((call) => call.method == 'initialize')
                    .arguments
                as Map;
        expect(settings['requestAlertPermission'], false);
        expect(settings['requestBadgePermission'], false);
        expect(settings['requestSoundPermission'], false);
      },
    );
  }

  test(
    'iOS resume repeats setup without requesting notification permission',
    () async {
      final (container, ble) = startup();
      await container.read(appInitializerProvider.future);
      await expectDiscovery(container, ble);
      await container
          .read(appInitializerProvider.notifier)
          .retry(requestPermissions: false);
      expect(container.read(appInitializerProvider).value, InitPhase.complete);
      expect(permissionRequests, [true, false]);
      await expectDiscovery(container, ble);
      expect(ble.discoveries.hasListener, true);
      expect(
        harness.notificationCalls.where((call) => call.method == 'initialize'),
        hasLength(2),
      );
    },
  );

  test(
    'a real notification platform error blocks setup and retry recovers discovery',
    () async {
      initializationError = PlatformException(code: 'notification_unavailable');
      final (container, ble) = startup();
      await expectLater(
        container.read(appInitializerProvider.future),
        throwsA(isA<PlatformException>()),
      );
      expect(container.read(appInitializerProvider).hasError, true);
      expect(ble.filters, isEmpty);
      initializationError = null;
      await container.read(appInitializerProvider.notifier).retry();
      expect(container.read(appInitializerProvider).value, InitPhase.complete);
      await expectDiscovery(container, ble);
    },
  );

  test(
    'iOS notification setup does not bypass denied Bluetooth permission',
    () async {
      final (container, ble) = startup(bluetoothGranted: false);
      expect(
        await container.read(appInitializerProvider.future),
        InitPhase.bluetoothDenied,
      );
      await harness.flushEvents();
      expect(ble.filters, isEmpty);
      expect(container.read(deviceManagerProvider).available, isEmpty);
    },
  );
}
