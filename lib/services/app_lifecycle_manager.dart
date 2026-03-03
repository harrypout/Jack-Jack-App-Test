import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/providers/selected_device_provider.dart';
import 'package:jackjack/providers/threshold_alert_provider.dart';
import 'package:jackjack/screens/manual_monitoring/providers/manual_monitoring_provider.dart';
import 'package:jackjack/screens/pairing/pods/available_devices.dart';
import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:jackjack/main.dart';

/// Manages app lifecycle events and coordinates between foreground UI and background service
class AppLifecycleManager with WidgetsBindingObserver {
  final WidgetRef ref;
  bool _backgroundServiceActive = false;

  /// Whether the app is currently in background (used by other providers to
  /// suppress spurious disconnect events during the background handoff)
  static bool isInBackground = false;

  AppLifecycleManager(this.ref);

  /// Initialize lifecycle observer
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _backgroundServiceActive = prefs.getBool("backgroundMonitoring") ?? false;
    debugPrint('🔄 AppLifecycleManager initialized (background: $_backgroundServiceActive)');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.inactive:
        debugPrint('⚪ App inactive');
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        debugPrint('⚪ App hidden');
        break;
    }
  }

  /// Called when app enters background (home button pressed, phone locked, etc.)
  void _onAppPaused() {
    debugPrint('🟡 App paused (going to background)');
    isInBackground = true;

    // Stop foreground scan — background service handles scanning if needed
    ref.read(deviceManagerProvider.notifier).stopScan();

    if (_backgroundServiceActive) {
      // Handle streaming state BEFORE device transfer
      final isStreaming = ref.read(manualMonitoringProvider).isStreaming;
      final backgroundAudioEnabled = prefs.getBool("backgroundAudio") ?? true;

      if (isStreaming) {
        if (!backgroundAudioEnabled) {
          // Stop streaming if background audio is disabled
          debugPrint('🎵 Stopping streaming - background audio disabled');
          ref.read(manualMonitoringProvider.notifier).stopStreaming();
        } else {
          // Transfer streaming state to background
          final streamingDuration = ref.read(manualMonitoringProvider).streamingDuration;
          final streamingDeviceId = ref.read(selectedDeviceProvider);

          debugPrint('🎵 Transferring streaming to background (duration: ${streamingDuration}s)');

          FlutterBackgroundService().invoke('startManualStreaming', {
            'deviceId': streamingDeviceId,
            'streamingDuration': streamingDuration,
          });

          // Pause foreground timer (background will take over)
          ref.read(manualMonitoringProvider.notifier).pauseTimer();
        }
      }

      // Get list of connected devices to transfer to background service
      final connectedDevices = ref.read(connectedDevicesProvider);

      // Filter out devices that user manually disconnected
      final deviceIds = connectedDevices.keys.where((deviceId) {
        final userDisconnected = prefs.getBool("user_disconnected_$deviceId") ?? false;
        if (userDisconnected) {
          debugPrint('📱 Foreground: Filtering out user-disconnected device: $deviceId');
        }
        return !userDisconnected;
      }).toList();

      final deviceNames = <String, String>{};
      for (final deviceId in deviceIds) {
        final device = connectedDevices[deviceId];
        if (device != null) {
          deviceNames[deviceId] = device.device.name;
        }
      }

      // Check if any devices are currently disconnected
      final connectedIds = ref.read(connectedDevicesTrackerProvider).value ?? {};
      final allDeviceIds = deviceIds.toSet();
      final disconnectedIds = allDeviceIds.difference(connectedIds);

      debugPrint(
        '📱 Transferring ${deviceIds.length} devices to background service '
        '(${disconnectedIds.length} disconnected, scan: ${disconnectedIds.isNotEmpty})'
      );

      // Transfer device list to background service
      FlutterBackgroundService().invoke('updateDeviceList', {
        'deviceIds': deviceIds,
        'deviceNames': deviceNames,
        'isStreaming': isStreaming && backgroundAudioEnabled,
        'shouldScan': disconnectedIds.isNotEmpty, // Start scan if any disconnected
      });

      // Only show notification if there are devices to monitor
      if (deviceIds.isNotEmpty) {
        FlutterBackgroundService().invoke('showNotification');
      }
    } else {
      debugPrint('⚠️  Background monitoring disabled - services may pause');
    }
  }

  /// Called when app returns to foreground
  void _onAppResumed() {
    debugPrint('🟢 App resumed (returning to foreground)');

    // Refresh background service status (user may have toggled in settings)
    _backgroundServiceActive = prefs.getBool("backgroundMonitoring") ?? false;

    if (_backgroundServiceActive) {
      // Set up listener BEFORE sending request to avoid race condition
      // where the response arrives before the listener is ready.
      StreamSubscription? stateSyncSub;
      stateSyncSub = FlutterBackgroundService().on('stateSync').listen((data) {
        if (data != null) {
          final isStreaming = data['isStreaming'] as bool? ?? false;
          final streamingDuration = data['streamingDuration'] as int? ?? 0;
          final disconnectedIds = List<String>.from(
            data['disconnectedDeviceIds'] as List? ?? [],
          );

          if (isStreaming) {
            debugPrint('🎵 Resuming streaming from background (duration: ${streamingDuration}s)');

            // Resume streaming in foreground with synced duration
            ref.read(manualMonitoringProvider.notifier)
                .resumeStreaming(streamingDuration);

            // Stop background timer (foreground has taken over)
            FlutterBackgroundService().invoke('stopManualStreaming');
          }

          // Sync disconnected device state from background
          for (final deviceId in disconnectedIds) {
            ref.read(connectedDevicesTrackerProvider.notifier).markDisconnected(deviceId);
          }

          // One-shot: cancel after first response
          stateSyncSub?.cancel();
        }
      });

      // Now send the request (listener is already active)
      FlutterBackgroundService().invoke('requestStateSync');

      // Timeout: cancel listener after 2 seconds if no response
      Future.delayed(const Duration(seconds: 2), () {
        stateSyncSub?.cancel();
      });

      debugPrint('📱 App resumed - transitioning from background to foreground');

      // Stop background scanning (foreground will handle it)
      FlutterBackgroundService().invoke('stopBackgroundScan');

      // Dismiss foreground notification when app is in foreground
      FlutterBackgroundService().invoke('dismissNotification');

      // DON'T release background device connections here.
      // The foreground's original BLE connections were lost during background,
      // so releasing background connections would disconnect the device with
      // nobody maintaining the connection. Background connections will be
      // cleaned up naturally next time the app goes to background
      // (updateDeviceList cancels old connections before creating new ones).
    }

    // Refresh scan to discover nearby devices
    ref.read(deviceManagerProvider.notifier).refreshScan();

    // Re-setup foreground threshold alerts — the foreground's BLE subscriptions
    // die during the background phase, so we need to re-subscribe.
    ref.read(thresholdAlertProvider.notifier).setupAlerts();

    // Delay clearing the background flag so any lingering disconnect events
    // from the BLE handoff are still suppressed during the transition.
    Future.delayed(const Duration(milliseconds: 1000), () {
      isInBackground = false;
      debugPrint('🟢 Background transition complete');
    });
  }

  /// Called when app is being killed
  void _onAppDetached() {
    debugPrint('⚪ App detaching/closing');

    if (!_backgroundServiceActive) {
      // Clean shutdown: background service will not continue
      debugPrint('ℹ️  App closing without background service');
    } else {
      // Background service will continue running
      debugPrint('ℹ️  App closing, background service will continue');
    }
  }

  /// Cleanup
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('🔄 AppLifecycleManager disposed');
  }
}
