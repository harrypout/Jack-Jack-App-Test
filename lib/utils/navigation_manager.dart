import 'package:flutter/material.dart';
import 'package:ble/screens/onboarding/onboarding_screen.dart';

class NavigationManager {
  static final initialRoute = OnboardingScreen.id;

  static final routes = <String, WidgetBuilder>{
    OnboardingScreen.id: (context) => const OnboardingScreen(),
  };
}
