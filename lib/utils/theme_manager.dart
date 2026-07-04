import 'package:jackjack/utils/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeManager {
  static double horizontalPadding = 20;

  // Radius scale: sm tags · md fields · lg cards · xl feature cards · full pills
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  static const brSm = BorderRadius.all(Radius.circular(radiusSm));
  static const brMd = BorderRadius.all(Radius.circular(radiusMd));
  static const brLg = BorderRadius.all(Radius.circular(radiusLg));
  static const brXl = BorderRadius.all(Radius.circular(radiusXl));
  static const brFull = BorderRadius.all(Radius.circular(radiusFull));

  // Elevation
  static const shadowSm = [
    BoxShadow(color: Color(0x0F4A5568), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const shadowMd = [
    BoxShadow(
      color: Color(0x144A5568),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];
  static const sageGlow = [
    BoxShadow(
      color: Color(0xE68EB8A8),
      offset: Offset(0, 8),
      blurRadius: 18,
      spreadRadius: -8,
    ),
  ];
  static const miniCardShadow = [
    BoxShadow(
      color: Color(0x734A5568),
      offset: Offset(0, 18),
      blurRadius: 40,
      spreadRadius: -20,
    ),
  ];
  static const sheetShadow = [
    BoxShadow(
      color: Color(0x384A5568),
      offset: Offset(0, -10),
      blurRadius: 30,
      spreadRadius: -16,
    ),
  ];

  // Motion
  static const durColor = Duration(milliseconds: 200);
  static const durTransform = Duration(milliseconds: 300);
  static const durFade = Duration(milliseconds: 400);
  static const durPage = Duration(milliseconds: 320);
  static const durDots = Duration(milliseconds: 220);

  // Display type: Fredoka for titles/gauge value; body stays Nunito Sans.
  // Fredoka is only imported at weights 400/500/600 — never request w700.
  static TextStyle get displayTitle => GoogleFonts.fredoka(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ColorManager.slate,
  );
  static TextStyle get displaySub => GoogleFonts.fredoka(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: ColorManager.slate,
  );
  static TextStyle get displayOnboardingTitle => GoogleFonts.fredoka(
    fontSize: 23,
    fontWeight: FontWeight.w600,
    color: ColorManager.slate,
  );
  static TextStyle get gaugeValue => GoogleFonts.fredoka(
    fontSize: 36,
    fontWeight: FontWeight.w500,
    color: ColorManager.slate,
    height: 1,
  );

  // Body/UI helpers (Nunito Sans comes from the app text theme)
  static const eyebrow = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: ColorManager.slate60,
    letterSpacing: 1.5,
  );
  static const rowLabel = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: ColorManager.slate,
  );
  static const meta = TextStyle(fontSize: 11, color: ColorManager.slate60);

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
