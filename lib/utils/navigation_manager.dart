import 'package:ble/screens/faq/faq_screen.dart';
import 'package:ble/main.dart';
import 'package:ble/screens/manual_monitoring/manual_monitoring_screen.dart';
import 'package:ble/screens/notifications/notification_screen.dart';
import 'package:ble/screens/pairing/pairing_screen.dart';
import 'package:ble/screens/settings/settings_screen.dart';
import 'package:ble/screens/threshold/threshold_screen.dart';
import 'package:ble/widgets/ble_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:ble/screens/onboarding/onboarding_screen.dart';

import '../screens/home/home_screen.dart';

class NavigationManager {
  static final initialRoute =
      (prefs.getBool('onboarding_status') ?? false)
          ? BLEBottomBar.id
          : OnboardingScreen.id;

  static final routes = <String, WidgetBuilder>{
    OnboardingScreen.id: (context) => const OnboardingScreen(),
    HomeScreen.id: (context) => const HomeScreen(),
    NotificationScreen.id: (context) => const NotificationScreen(),
    ThresholdScreen.id: (context) => const ThresholdScreen(),
    FAQScreen.id: (context) => const FAQScreen(),
    SettingsScreen.id: (context) => const SettingsScreen(),
    PairingScreen.id: (context) => const PairingScreen(),
    ManualMonitoringScreen.id: (context) => const ManualMonitoringScreen(),
    BLEBottomBar.id: (context) => const BLEBottomBar(),
  };
}
