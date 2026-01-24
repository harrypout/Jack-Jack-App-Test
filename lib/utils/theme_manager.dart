import 'package:jackjack/utils/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeManager {
  static double horizontalPadding = 20;

  static appTheme(BuildContext context) {
    return ThemeData.light(useMaterial3: true).copyWith(
      textTheme: GoogleFonts.nunitoSansTextTheme(Theme.of(context).textTheme),
      colorScheme: ColorScheme.fromSeed(seedColor: ColorManager.accent),
      appBarTheme: const AppBarTheme(
        surfaceTintColor: ColorManager.transparent,
        backgroundColor: ColorManager.background,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        modalBackgroundColor: ColorManager.background,
        surfaceTintColor: ColorManager.transparent,
      ),
      scaffoldBackgroundColor: ColorManager.background,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ColorManager.background,
      ),
    );
  }

  static final statusBar = SystemUiOverlayStyle(
    statusBarColor: ColorManager.transparent,
    statusBarIconBrightness: Brightness.dark,
  );
}
