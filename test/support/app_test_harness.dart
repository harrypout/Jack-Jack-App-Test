import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/main.dart' as app;
import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/models/ble_service.dart';
import 'package:jackjack/models/ble_uuids.dart';
import 'package:jackjack/models/notification_sf.dart';
import 'package:jackjack/providers/alert_clock_provider.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/providers/notifications_provider.dart';
import 'package:jackjack/providers/paired_devices.dart';
import 'package:jackjack/services/device_name_manager.dart';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const deviceA = 'test-pebble-a';
const deviceB = 'test-pebble-b';
const testServiceId = '00000000-0000-0000-0000-000000000001';
const testCharacteristicId = '00000000-0000-0000-0000-000000000002';

/// Only platform boundaries are fake. Provider logic, persistence parsing and
/// notification configuration are the real application implementations.
class AppTestHarness {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final notificationCalls = <MethodCall>[];
  late FakeBackgroundService background;
  DateTime now = DateTime.utc(2026, 9, 13, 12);

  List<Map<String, dynamic>> get shownNotifications =>
      notificationCalls
          .where((call) => call.method == 'show')
          .map((call) => Map<String, dynamic>.from(call.arguments as Map))
          .toList();

  void install() {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      app.prefs = await SharedPreferences.getInstance();
    });
    setUp(() async {
      await app.prefs.clear();
      PairedDevicesUUID.list = [];
      await DeviceNameManager.instance.initialize();
      now = DateTime.utc(2026, 9, 13, 12);
      background = FakeBackgroundService();
      FlutterBackgroundServicePlatform.instance = background;
      IOSFlutterLocalNotificationsPlugin.registerWith();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async {
          notificationCalls.add(call);
          return call.method == 'initialize' ? true : null;
        },
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('PonnamKarthik/fluttertoast'),
        (call) async => true,
      );
      await NotificationManager.instance.initializePlugin();
      notificationCalls.clear();
    });
    tearDown(() async {
      await background.close();
      debugDefaultTargetPlatformOverride = null;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        null,
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('PonnamKarthik/fluttertoast'),
        null,
      );
    });
  }

  ProviderContainer container({FakeConnectedDevices? connected}) {
    final result = ProviderContainer(
      overrides: [
        alertClockProvider.overrideWithValue(() => now),
        connectedDevicesProvider.overrideWith(
          () => connected ?? FakeConnectedDevices({}),
        ),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  List<NotificationSF> history(ProviderContainer container) =>
      container
          .read(notificationsProvider)
          .expand((group) => group.notifications)
          .toList();

  Future<void> flushEvents() async {
    // Completes the queued stream callbacks; no timing assumptions or sleeps.
    await Future<void>.delayed(Duration.zero);
  }
}

class FakeBackgroundService extends FlutterBackgroundServicePlatform {
  final channels = <String, StreamController<Map<String, dynamic>?>>{};
  final commands = <(String, Map<String, dynamic>?)>[];

  @override
  Stream<Map<String, dynamic>?> on(String method) =>
      channels.putIfAbsent(method, () => StreamController.broadcast()).stream;
  @override
  void invoke(String method, [Map<String, dynamic>? args]) {
    commands.add((method, args));
  }

  @override
  Future<bool> configure({
    required IosConfiguration iosConfiguration,
    required AndroidConfiguration androidConfiguration,
  }) async => true;
  @override
  Future<bool> start() async => true;
  @override
  Future<bool> isServiceRunning() async => true;

  void alert(String id, {int value = 1, String? name}) {
    channels['thresholdAlert']!.add({
      'deviceId': id,
      'deviceName': name ?? id,
      'threshold': value,
    });
  }

  Future<void> close() async {
    for (final channel in channels.values) {
      await channel.close();
    }
  }
}

class FakeService extends BLEService {
  int? readBack;
  Object? writeError;
  Object? readError;
  int readCount = 0;
  final writes = <int>[];
  Completer<void>? writeGate;

  FakeService({int value = 75, this.readBack, this.writeError, this.readError})
    : super(
        deviceId: deviceA,
        type: BLEServiceType.getInt,
        uuid: BLEUUIDS(
          name: 'test',
          service: testServiceId,
          characteristic: testCharacteristicId,
        ),
        data: value,
      );

  @override
  Future<void> getValue() async {
    readCount++;
    if (readError != null) throw readError!;
    if (readBack != null) data = readBack;
  }

  @override
  Future<void> setValue(int value) async {
    writes.add(value);
    if (writeGate != null) await writeGate!.future;
    if (writeError != null) throw writeError!;
    data = value;
  }
}

class FakeConnectedDevices extends ConnectedDevices {
  final Map<String, BLEDevice> initialDevices;
  int playCalls = 0;
  int stopCalls = 0;
  FakeConnectedDevices(this.initialDevices);
  @override
  Map<String, BLEDevice> build() => Map.of(initialDevices);
  void replace(Map<String, BLEDevice> devices) => state = Map.of(devices);
  @override
  void playAudio() {
    playCalls++;
  }

  @override
  Future<void> stopAudio() async {
    stopCalls++;
  }

  // removeDevice is intentionally inherited: regressions exercise the real code.
}

BLEDevice testDevice({
  String id = deviceA,
  String? name,
  FakeService? read,
  FakeService? write,
  Stream<int>? alerts,
  FakeService? soundSwitch,
  FakeService? soundRead,
}) {
  return BLEDevice(
    device: DiscoveredDevice(
      id: id,
      name: name ?? id,
      serviceData: {},
      serviceUuids: [],
      manufacturerData: Uint8List(0),
      rssi: -40,
    ),
    getThreshold: read ?? FakeService(),
    setThreshold: write ?? FakeService(),
    getBattery: FakeService(value: 60),
    thresholdAlert: BLEService(
      deviceId: id,
      type: BLEServiceType.stream,
      uuid: BLEUUIDS(
        name: 'alert',
        service: testServiceId,
        characteristic: testCharacteristicId,
      ),
      qualifiedCharacteristic: QualifiedCharacteristic(
        deviceId: id,
        serviceId: Uuid.parse(testServiceId),
        characteristicId: Uuid.parse(testCharacteristicId),
      ),
      data: alerts ?? const Stream<int>.empty(),
    ),
    getSoundLevel: soundRead ?? FakeService(),
    setSoundLevel: soundSwitch ?? FakeService(),
    getSound: FakeService(),
    setSound: FakeService(),
  );
}

class FakeBleClient implements FlutterReactiveBle {
  List<int> readBytes = [75];
  Object? readError;
  Object? writeError;
  final writes = <(QualifiedCharacteristic, List<int>)>[];
  final notifications = StreamController<List<int>>.broadcast();
  @override
  Future<List<int>> readCharacteristic(
    QualifiedCharacteristic characteristic,
  ) async {
    if (readError != null) throw readError!;
    return List.of(readBytes);
  }

  @override
  Future<void> writeCharacteristicWithResponse(
    QualifiedCharacteristic characteristic, {
    required List<int> value,
  }) async {
    writes.add((characteristic, List.of(value)));
    if (writeError != null) throw writeError!;
  }

  @override
  Stream<List<int>> subscribeToCharacteristic(
    QualifiedCharacteristic characteristic,
  ) => notifications.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(
        'Unexpected BLE operation: ${invocation.memberName}',
      );
}
