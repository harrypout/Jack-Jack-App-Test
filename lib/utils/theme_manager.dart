import 'package:ble/utils/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeManager {
  static appTheme(BuildContext context) {
    return ThemeData.light(useMaterial3: true).copyWith(
      textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
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
