import 'package:jackjack/utils/color_manager.dart';
import 'package:flutter/material.dart';

/// Presentation-only colour rules from the redesign's "colour-diverse"
/// treatments. Pure functions of values the UI already displays — no state,
/// no side effects.

/// The visual warning margin is five displayed dB at every alert setting.
/// It does not change the firmware threshold or alert timing.
enum GaugeLevelBand {
  unknown('Alert setting unavailable', ColorManager.slate60),
  below('Below alert setting', ColorManager.sage),
  near('Near alert setting', ColorManager.yellow),
  above('At or above alert setting', ColorManager.coral);

  const GaugeLevelBand(this.label, this.color);
  final String label;
  final Color color;
}

GaugeLevelBand gaugeLevelBand(double? value, int? threshold) {
  if (value == null || threshold == null || threshold <= 0 || threshold > 120) {
    return GaugeLevelBand.unknown;
  }
  if (value >= threshold) return GaugeLevelBand.above;
  if (value >= threshold - 5) return GaugeLevelBand.near;
  return GaugeLevelBand.below;
}

Color gaugeArcColor(double value, int? threshold) =>
    gaugeLevelBand(value, threshold).color;

/// Battery-as-status: coral under 30%, yellow under 50%, otherwise neutral.
Color batteryValueColor(int? pct) {
  if (pct == null) return ColorManager.slate60;
  if (pct < 30) return ColorManager.coralIcon;
  if (pct < 50) return ColorManager.yellowIcon;
  return ColorManager.slate60;
}

/// Device identity tints. What counts as "primary" is per-screen, matching
/// the design mock: the selected device on Home, paired devices on Connect —
/// so the same device may be sage on one screen and tinted on another.
/// Non-primary devices get a coral/yellow identity derived from their id,
/// stable across list reorders and app restarts. String.hashCode is
/// deliberately avoided — Dart does not guarantee it stable across runs.
enum DeviceTone {
  sage(
    tintBg: ColorManager.sageTint10,
    iconColor: ColorManager.sage,
    gradient: LinearGradient(
      begin: Alignment(-0.5, -0.87),
      end: Alignment(0.5, 0.87),
      colors: [ColorManager.sageGradStart, ColorManager.sageGradEnd],
    ),
  ),
  coral(
    tintBg: ColorManager.coralTint10,
    iconColor: ColorManager.coralIcon,
    gradient: LinearGradient(
      begin: Alignment(-0.5, -0.87),
      end: Alignment(0.5, 0.87),
      colors: [ColorManager.coralGradStart, ColorManager.coralGradEnd],
    ),
  ),
  yellow(
    tintBg: ColorManager.yellowTint10,
    iconColor: ColorManager.yellowIcon,
    gradient: LinearGradient(
      begin: Alignment(-0.5, -0.87),
      end: Alignment(0.5, 0.87),
      colors: [ColorManager.yellowDot, ColorManager.yellowIcon],
    ),
  );

  const DeviceTone({
    required this.tintBg,
    required this.iconColor,
    required this.gradient,
  });

  final Color tintBg;
  final Color iconColor;
  final LinearGradient gradient;
}

DeviceTone deviceTone({required String id, required bool isPrimary}) {
  if (isPrimary) return DeviceTone.sage;
  final sum = id.codeUnits.fold(0, (a, b) => a + b);
  return sum.isEven ? DeviceTone.coral : DeviceTone.yellow;
}
