import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/providers/paired_devices.dart';
import 'package:jackjack/services/background_service_manager.dart';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:jackjack/utils/permission_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'app_initializer.g.dart';

enum InitPhase { pending, bluetoothDenied, notificationsDenied, complete }

class ReadinessChecks {
  final Future<bool> Function(bool request) bluetooth;
  final Future<bool> Function(bool request) notifications;
  final Future<void> Function() initialize;
  ReadinessChecks({
    required this.bluetooth,
    required this.notifications,
    required this.initialize,
  });
}

final readinessChecksProvider = Provider<ReadinessChecks>(
  (ref) => ReadinessChecks(
    bluetooth: (request) => PermissionManager.check(request: request),
    notifications:
        (request) =>
            request
                ? NotificationManager.instance.requestPermission()
                : Permission.notification.isGranted,
    initialize: () async {
      await NotificationManager.instance.initializePlugin();
      await BackgroundServiceManager.initialize();
    },
  ),
);
bool canUseBluetooth(InitPhase? phase) =>
    phase == InitPhase.complete || phase == InitPhase.notificationsDenied;

@Riverpod(keepAlive: true)
class AppInitializer extends _$AppInitializer {
  @override
  Future<InitPhase> build() => _run(true);
  Future<InitPhase> _run(bool request) async {
    await PairedDevicesUUID.loadFromPrefs();
    final checks = ref.read(readinessChecksProvider);
    final bluetooth = await checks.bluetooth(request);
    await checks.initialize();
    final notifications = await checks.notifications(request);
    if (!bluetooth) return InitPhase.bluetoothDenied;
    await BackgroundServiceManager.startService();
    return notifications ? InitPhase.complete : InitPhase.notificationsDenied;
  }

  Future<void> retry({bool requestPermissions = true}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _run(requestPermissions));
  }
}

@Riverpod(keepAlive: true)
class BleStatusNotifier extends _$BleStatusNotifier {
  @override
  BleStatus build() {
    final ble = ref.read(bleClientProvider);
    final subscription = ble.statusStream.listen(
      (status) {
        state = status;
      },
      onError: (Object _) {
        state = BleStatus.unknown;
      },
    );
    ref.onDispose(subscription.cancel);
    return ble.status;
  }
}
