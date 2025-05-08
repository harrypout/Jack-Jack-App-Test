import 'package:ble/providers/threshold_alert_provider.dart';
import 'package:ble/utils/env_manager.dart';
import 'package:ble/utils/permission_manager.dart';
import 'package:ble/utils/navigation_manager.dart';
import 'package:ble/utils/notification_manager.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final SharedPreferences prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvManager.getInstance();
  print("env");
  prefs = await SharedPreferences.getInstance();
  print("prefs");
  await NotificationManager.instance.initialize();
  print("notif");
  await PermissionManager.check();
  print("location");
  await FlutterBluePlus.turnOn();
  print("bton");
  FlutterBluePlus.startScan(
    timeout: const Duration(seconds: 10),
    withServices: [
      Guid(configs.setThresholdUUIDS.service),
      // ...configs.uuids.map((uuid)=> Guid(uuid.service))
    ],
  );
  print("scan");
  runApp(ProviderScope(child: const BLE()));
}

class BLE extends ConsumerWidget {
  const BLE({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(thresholdAlertProvider.notifier).setupAlerts();
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
