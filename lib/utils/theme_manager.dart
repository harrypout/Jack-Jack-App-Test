import 'package:jackjack/utils/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeManager {
  static double horizontalPadding = 20;

  static appTheme(BuildContext context) {
    return ThemeData.light(useMaterial3: true).copyWith(
      // Lato is bundled in assets/fonts (see pubspec) instead of being
      // fetched at runtime by google_fonts, which added a network download
      // on first launch.
      textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Lato'),
      colorScheme: ColorScheme.fromSeed(seedColor: ColorManager.accent),
      appBarTheme: const AppBarTheme(
        surfaceTintColor: ColorManager.transparent,
        backgroundColor: ColorManager.white,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        modalBackgroundColor: ColorManager.white,
        surfaceTintColor: ColorManager.transparent,
      ),
      scaffoldBackgroundColor: ColorManager.white,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ColorManager.white,
      ),
    );
  }

  static final statusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  );
}
