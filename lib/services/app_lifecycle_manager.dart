import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jackjack/main.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/providers/notifications_provider.dart';
import 'package:jackjack/services/app_initializer.dart';
import 'package:jackjack/services/background_service_manager.dart';
import 'package:jackjack/screens/pairing/pods/available_devices.dart';

final monitoringErrorProvider = StateProvider<String?>((ref) => null);

class AppLifecycleManager with WidgetsBindingObserver {
  final WidgetRef ref;
  static bool isInBackground = false;
  static AppLifecycleManager? active;
  Future<void> _transition = Future.value();
  bool _disposed = false;
  AppLifecycleManager(this.ref);
  void initialize() {
    active = this;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        state != AppLifecycleState.paused) {
      return;
    }
    isInBackground = state == AppLifecycleState.paused;
    retry();
  }

  void retry() {
    _transition = _transition.then((_) async {
      if (_disposed) return;
      final background = isInBackground;
      try {
        if (background) {
          ref.read(deviceManagerProvider.notifier).stopScan();
          if (Platform.isAndroid &&
              (prefs.getBool('backgroundMonitoring') ?? true)) {
            await BackgroundServiceManager.startService();
            if (_disposed || !isInBackground) return;
            final devices =
                ref.read(connectedDevicesProvider.notifier).desiredDevices;
            final desired =
                devices.keys
                    .where(
                      (id) =>
                          prefs.getBool('user_disconnected_$id') != true &&
                          prefs.getBool('forgotten_$id') != true,
                    )
                    .toList();
            await ref.read(connectedDevicesProvider.notifier).suspend();
            await BackgroundServiceManager.request('acquire', {
              'deviceIds': desired,
              'deviceNames': {for (final id in desired) id: devices[id]!.name},
            });
          }
          // iOS keeps its main-engine Core Bluetooth subscriptions. Dart timers
          // are best effort while suspended; BLE events and resume drive recovery.
        } else {
          if (Platform.isAndroid &&
              await BackgroundServiceManager.isServiceRunning()) {
            await BackgroundServiceManager.request('release');
          }
          if (_disposed) return;
          await ref.read(notificationsProvider.notifier).reload();
          if (ref.read(appInitializerProvider).isLoading) {
            await ref.read(appInitializerProvider.future);
          } else {
            await ref
                .read(appInitializerProvider.notifier)
                .retry(requestPermissions: false);
          }
          if (_disposed) return;
          if (canUseBluetooth(ref.read(appInitializerProvider).valueOrNull)) {
            await ref.read(connectedDevicesProvider.notifier).resume();
          } else {
            await ref.read(connectedDevicesProvider.notifier).suspend();
          }
          ref.read(deviceManagerProvider.notifier).refreshScan();
        }
        if (!_disposed) ref.read(monitoringErrorProvider.notifier).state = null;
      } catch (error) {
        if (!_disposed) {
          ref.read(monitoringErrorProvider.notifier).state =
              'Monitoring could not switch between foreground and background. Open Jack Jack and retry.';
          debugPrint('Monitoring transition failed: $error');
        }
      }
    });
  }

  void dispose() {
    _disposed = true;
    if (active == this) active = null;
    WidgetsBinding.instance.removeObserver(this);
  }
}
