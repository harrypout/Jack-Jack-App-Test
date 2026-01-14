import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/screens/manual_monitoring/providers/manual_monitoring_provider.dart';
import 'package:jackjack/screens/pairing/pods/available_devices.dart';
import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:jackjack/main.dart';

/// Manages app lifecycle events and coordinates between foreground UI and background service
class AppLifecycleManager with WidgetsBindingObserver {
  final WidgetRef ref;
  bool _backgroundServiceActive = false;

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

    if (_backgroundServiceActive) {
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
      final isStreaming = ref.read(manualMonitoringProvider).isStreaming;

      FlutterBackgroundService().invoke('updateDeviceList', {
        'deviceIds': deviceIds,
        'deviceNames': deviceNames,
        'isStreaming': isStreaming,
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

    // Refresh scan first to ensure foreground is ready to take over
    ref.read(deviceManagerProvider.notifier).refreshScan();

    if (_backgroundServiceActive) {
      debugPrint('📱 App resumed - releasing background monitoring to foreground');

      // Stop background scanning (foreground will handle it)
      FlutterBackgroundService().invoke('stopBackgroundScan');

      // Dismiss foreground notification when app is in foreground
      FlutterBackgroundService().invoke('dismissNotification');

      // Give foreground a moment to initialize before releasing background connections
      Future.delayed(const Duration(milliseconds: 500), () {
        // Release all device connections - foreground has taken over
        FlutterBackgroundService().invoke('updateDeviceList', {
          'deviceIds': [],
          'deviceNames': {},
          'isStreaming': false,
          'shouldScan': false,
        });
      });
    }
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
