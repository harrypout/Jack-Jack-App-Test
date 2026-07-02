import 'package:jackjack/providers/periodic_task_provider.dart';
import 'package:jackjack/screens/pairing/pods/available_devices.dart';
import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:jackjack/services/app_initializer.dart';
import 'package:jackjack/services/app_lifecycle_manager.dart';
import 'package:jackjack/services/device_name_manager.dart';
import 'package:jackjack/utils/env_manager.dart';
import 'package:jackjack/utils/navigation_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final SharedPreferences prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Only the two hard dependencies before runApp():
    // - SharedPreferences: needed by NavigationManager.initialRoute
    // - EnvManager: needed by BLE UUID configs
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      EnvManager.getInstance(),
    ]);

    prefs = results[0] as SharedPreferences;

    // Initialize device name manager
    await DeviceNameManager.instance.initialize();

    // Enable background monitoring by default
    if (!prefs.containsKey("backgroundMonitoring")) {
      await prefs.setBool("backgroundMonitoring", true);
    }
  } catch (e, s) {
    // Without this guard any failure here (e.g. a missing/invalid .env)
    // throws out of main() and the app crash-loops on launch with no
    // feedback.
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
    // Trigger deferred initialization (permissions, notifications, background service)
    ref.watch(appInitializerProvider);

    // These providers are safe to watch before init completes — they gate
    // their BLE operations on appInitializerProvider state internally.
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
