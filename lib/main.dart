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
  await EnvManager.getInstance();
  prefs = await SharedPreferences.getInstance();
  await NotificationManager.instance.initialize();
  await PermissionManager.check();
  await BatteryOptimizationManager.check();
  await PairedDevicesUUID.loadFromPrefs();
  runApp(ProviderScope(child: const BLE()));
}

class BLE extends ConsumerWidget {
  const BLE({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(thresholdAlertProvider.notifier).setupAlerts();
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
