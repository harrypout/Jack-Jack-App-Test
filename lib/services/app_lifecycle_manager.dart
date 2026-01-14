import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/screens/manual_monitoring/providers/manual_monitoring_provider.dart';
import 'package:jackjack/screens/pairing/pods/available_devices.dart';
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
    debugPrint('🔴 App entering background');

    if (_backgroundServiceActive) {
      // Transfer monitoring responsibility to background service
      final connectedDevices = ref.read(connectedDevicesProvider);
      final deviceIds = connectedDevices.keys.toList();
      final deviceNames = <String, String>{};
      for (var entry in connectedDevices.entries) {
        deviceNames[entry.key] = entry.value.device.name;
      }
      final isStreaming = ref.read(manualMonitoringProvider).isStreaming;

      FlutterBackgroundService().invoke('updateDeviceList', {
        'deviceIds': deviceIds,
        'deviceNames': deviceNames,
        'isStreaming': isStreaming,
      });

      debugPrint('✅ Transferred ${deviceIds.length} devices to background service');
      debugPrint('   Streaming: $isStreaming');
    } else {
      debugPrint('⚠️  Background monitoring disabled - services may pause');
    }
  }

  /// Called when app returns to foreground
  void _onAppResumed() {
    debugPrint('🟢 App returning to foreground');

    // Refresh background service status (user may have toggled in settings)
    _backgroundServiceActive = prefs.getBool("backgroundMonitoring") ?? false;

    // Restart foreground scan to discover nearby devices
    ref.read(deviceManagerProvider.notifier).refreshScan();
    debugPrint('✅ Refreshed device scan');

    if (_backgroundServiceActive) {
      // Request state sync from background service
      FlutterBackgroundService().invoke('requestStateSync', {});
      debugPrint('✅ Requested state sync from background service');

      // Listen for state sync response
      // The providers will handle incoming events from background service
    } else {
      debugPrint('ℹ️  Background monitoring disabled, using foreground only');
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
