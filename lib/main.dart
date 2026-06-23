import 'dart:io';

import 'package:jackjack/providers/paired_devices.dart';
import 'package:jackjack/providers/periodic_task_provider.dart';
import 'package:jackjack/providers/threshold_alert_provider.dart';
import 'package:jackjack/screens/pairing/pods/available_devices.dart';
import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:jackjack/utils/battery_optimization_manager.dart';
import 'package:jackjack/utils/env_manager.dart';
import 'package:jackjack/utils/permission_manager.dart';
import 'package:jackjack/utils/navigation_manager.dart';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final SharedPreferences prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Only the work the first frame depends on. Permission prompts and the
    // battery-optimization dialog are deferred until after the UI is up.
    await EnvManager.getInstance();
    prefs = await SharedPreferences.getInstance();
    await NotificationManager.instance.initialize();
    await PairedDevicesUUID.loadFromPrefs();
  } catch (e, s) {
    // Previously any failure here (e.g. a missing/invalid .env) threw out of
    // main() and the app crash-looped on launch with no feedback.
    debugPrint("Startup initialization failed: $e\n$s");
    runApp(StartupErrorApp(message: e.toString()));
    return;
  }
  runApp(ProviderScope(child: const BLE()));
}

class StartupErrorApp extends StatelessWidget {
  final String message;
  const StartupErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong while starting the app.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BLE extends ConsumerStatefulWidget {
  const BLE({super.key});

  @override
  ConsumerState<BLE> createState() => _BLEState();
}

class _BLEState extends ConsumerState<BLE> {
  @override
  void initState() {
    super.initState();
    // Instantiate the long-lived services once. They are keepAlive, so
    // reading (not watching) them here keeps them alive for the app's
    // lifetime without rebuilding the whole tree on every scan/connection
    // event — which is what watching them at the root previously did.
    ref.read(connectedDevicesTrackerProvider);
    ref.read(deviceManagerProvider);
    ref.read(periodicTaskServiceProvider);
    ref.read(thresholdAlertProvider.notifier).setupAlerts();

    // Defer permission prompts until after the first frame so the UI renders
    // immediately instead of blocking on system dialogs.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationManager.instance.requestPermission();
      await PermissionManager.check();
      if (Platform.isAndroid) {
        await BatteryOptimizationManager.check();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
