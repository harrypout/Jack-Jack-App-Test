import 'package:ble/providers/paired_devices.dart';
import 'package:ble/providers/threshold_alert_provider.dart';
import 'package:ble/utils/env_manager.dart';
import 'package:ble/utils/navigation_manager.dart';
import 'package:ble/utils/notification_manager.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

late final SharedPreferences prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvManager.getInstance();
  print(configs.uuids);
  prefs = await SharedPreferences.getInstance();
  await PairedDevicesUUID.loadFromPrefs();
  await NotificationManager.instance.initialize();
  await checkLocationPremission();
  await FlutterBluePlus.turnOn();
  runApp(ProviderScope(child: const BLE()));
}

class BLE extends ConsumerWidget {
  const BLE({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Future.microtask(() => ref
    //     .read(pairedDevicesUUIDProvider.notifier)
    //     .loadFromPrefs());
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



Future<Position> checkLocationPremission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  LocationPermission permission = await Geolocator.checkPermission();
  if (!serviceEnabled) {
    // do what you want
  }

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // toast('Please location permission');
      // logger.w("get User LocationPosition()");
      await Geolocator.openAppSettings();

      // throw '${language.lblLocationPermissionDenied}';
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw "language lbl Location Permission Denied Permanently, please enable it from setting";
  }

  return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((value) {
    return value;
  }).catchError((e) async {
    return await Geolocator.getLastKnownPosition().then((value) async {
      if (value != null) {
        return value;
      } else {
        throw "lbl Enable Location";
      }
    }).catchError((e) {
      print(e.toString());
    });
  });
}