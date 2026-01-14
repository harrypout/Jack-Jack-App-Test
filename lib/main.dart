import 'dart:io';

import 'package:jackjack/providers/paired_devices.dart';
import 'package:jackjack/providers/periodic_task_provider.dart';
import 'package:jackjack/screens/pairing/pods/available_devices.dart';
import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:jackjack/services/app_lifecycle_manager.dart';
import 'package:jackjack/services/background_service_manager.dart';
import 'package:jackjack/utils/battery_optimization_manager.dart';
import 'package:jackjack/utils/env_manager.dart';
import 'package:jackjack/utils/permission_manager.dart';
import 'package:jackjack/utils/navigation_manager.dart';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:jackjack/utils/platform_channel_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final SharedPreferences prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvManager.getInstance();
  prefs = await SharedPreferences.getInstance();
  await PairedDevicesUUID.loadFromPrefs();

  // Request all permissions upfront before showing UI
  await _requestAllPermissions();

  // Enable background monitoring by default
  if (!prefs.containsKey("backgroundMonitoring")) {
    await prefs.setBool("backgroundMonitoring", true);
  }

  // Initialize background service
  await BackgroundServiceManager.initialize();
  PlatformChannelManager.setupBackgroundTaskHandler();

  runApp(ProviderScope(child: const BLE()));

  // Start background service after app starts (ensures notification channel is ready)
  final backgroundEnabled = prefs.getBool("backgroundMonitoring") ?? true;
  if (backgroundEnabled) {
    // Delay to ensure the app and notification channels are fully initialized
    Future.delayed(const Duration(seconds: 1), () async {
      await BackgroundServiceManager.startService();
    });
  }
}

Future<void> _requestAllPermissions() async {
  debugPrint('🔐 Requesting all permissions upfront...');

  // 1. BLE permissions (location on older Android, bluetooth on newer)
  await PermissionManager.check();

  // 2. Notification permissions
  await NotificationManager.instance.initialize();

  // 3. Battery optimization exemption (for reliable background service - Android only)
  if (Platform.isAndroid) {
    final isIgnoring = await PlatformChannelManager.isIgnoringBatteryOptimizations();
    if (!isIgnoring) {
      debugPrint('🔋 Requesting battery optimization exemption...');
      await PlatformChannelManager.requestBatteryOptimizationExemption();
    }
    await BatteryOptimizationManager.check();
  }

  debugPrint('✅ All permissions requested');
}

class BLE extends ConsumerStatefulWidget {
  const BLE({super.key});

  @override
  ConsumerState<BLE> createState() => _BLEState();
}

class _BLEState extends ConsumerState<BLE> {
  late AppLifecycleManager _lifecycleManager;

  @override
  void initState() {
    super.initState();
    _lifecycleManager = AppLifecycleManager(ref);
    _lifecycleManager.initialize();
  }

  @override
  void dispose() {
    _lifecycleManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Alert setup happens automatically in connected_devices_provider.dart:254
    ref.watch(connectedDevicesTrackerProvider);
    ref.watch(deviceManagerProvider);
    ref.watch(periodicTaskServiceProvider);
    return AnnotatedRegion(
      value: ThemeManager.statusBar,
      child: MaterialApp(
        title: 'BLE',
        themeMode: ThemeMode.light,
        theme: ThemeManager.appTheme(context),
        initialRoute: NavigationManager.initialRoute,
        routes: NavigationManager.routes,
      ),
    );
  }
}
