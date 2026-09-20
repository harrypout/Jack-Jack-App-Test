import 'package:jackjack/screens/contact_us/contact_us_screen.dart';
import 'package:jackjack/screens/faq/faq_screen.dart';
import 'package:jackjack/main.dart';
import 'package:jackjack/screens/notifications/notification_screen.dart';
import 'package:jackjack/screens/pairing/pairing_screen.dart';
import 'package:jackjack/screens/settings/settings_screen.dart';
import 'package:jackjack/screens/threshold/threshold_screen.dart';
import 'package:jackjack/widgets/ble_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:jackjack/screens/onboarding/onboarding_screen.dart';

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
    BLEBottomBar.id: (context) => const BLEBottomBar(),
    ContactUsScreen.id: (context) => const ContactUsScreen(),
  };
}
