import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:jackjack/main.dart';
import 'package:jackjack/providers/paired_devices.dart';
import 'package:jackjack/services/background_service_manager.dart';
import 'package:jackjack/utils/battery_optimization_manager.dart';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:jackjack/utils/permission_manager.dart';
import 'package:jackjack/utils/platform_channel_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_initializer.g.dart';

enum InitPhase { pending, permissionsGranted, complete }

@Riverpod(keepAlive: true)
class AppInitializer extends _$AppInitializer {
  @override
  Future<InitPhase> build() async {
    return _runDeferredInit();
  }

  Future<InitPhase> _runDeferredInit() async {
    // Step 1: Load paired device UUIDs (fast, needed before scan results arrive)
    await PairedDevicesUUID.loadFromPrefs();

    // Step 2: Request BLE permissions (critical — gates BLE scanning)
    final permissionsGranted = await PermissionManager.check();
    if (!permissionsGranted) {
      throw Exception('BLE permissions were denied. Please grant Bluetooth permissions in Settings.');
    }
    // Notify watchers that BLE permissions are ready — scan can start now.
    // We update state mid-build by using ref.notifyListeners() won't work here,
    // but watchers will see permissionsGranted once this future completes.
    // Instead, we'll check the phase from the data value.

    // Step 3: Non-critical init — errors are caught individually
    try {
      await Future.wait([
        NotificationManager.instance.initializePlugin(),
        BackgroundServiceManager.initialize(),
      ]);
    } catch (e) {
      debugPrint('⚠️ Non-critical init error (notifications/background): $e');
    }

    // Step 4: Request notification permission (may show dialog)
    try {
      await NotificationManager.instance.requestPermission();
    } catch (e) {
      debugPrint('⚠️ Notification permission request failed: $e');
    }

    // Step 5: Setup platform channel handler
    PlatformChannelManager.setupBackgroundTaskHandler();

    // Step 6: Start background service
    try {
      final backgroundEnabled = prefs.getBool("backgroundMonitoring") ?? true;
      if (backgroundEnabled) {
        await BackgroundServiceManager.startService();
      }
    } catch (e) {
      debugPrint('⚠️ Background service start failed: $e');
    }

    // Step 7: Battery optimization (Android only, lowest priority)
    if (Platform.isAndroid) {
      try {
        final isIgnoring =
            await PlatformChannelManager.isIgnoringBatteryOptimizations();
        if (!isIgnoring) {
          await PlatformChannelManager.requestBatteryOptimizationExemption();
        }
        await BatteryOptimizationManager.check();
      } catch (e) {
        debugPrint('⚠️ Battery optimization check failed: $e');
      }
    }

    debugPrint('✅ App initialization complete');
    return InitPhase.complete;
  }

  /// Retry initialization from scratch (e.g., after permission denial)
  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _runDeferredInit());
  }
}

/// Monitors Bluetooth hardware power state.
/// Emits BleStatus.ready when BT is on, BleStatus.poweredOff when off, etc.
@Riverpod(keepAlive: true)
class BleStatusNotifier extends _$BleStatusNotifier {
  StreamSubscription<BleStatus>? _subscription;

  @override
  BleStatus build() {
    final ble = FlutterReactiveBle();
    _subscription = ble.statusStream.listen((status) {
      state = status;
    });
    ref.onDispose(() => _subscription?.cancel());
    return BleStatus.unknown;
  }
}
