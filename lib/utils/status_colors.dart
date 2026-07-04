import 'package:jackjack/utils/color_manager.dart';
import 'package:flutter/material.dart';

/// Presentation-only colour rules from the redesign's "colour-diverse"
/// treatments. Pure functions of values the UI already displays — no state,
/// no side effects.

/// Gauge arc: sage below 82% of threshold, yellow approaching, coral over.
Color gaugeArcColor(double value, int threshold) {
  if (threshold <= 0) return ColorManager.sage;
  final ratio = value / threshold;
  if (ratio >= 1.0) return ColorManager.coral;
  if (ratio >= 0.82) return ColorManager.yellow;
  return ColorManager.sage;
}

/// Battery-as-status: coral under 30%, yellow under 50%, otherwise neutral.
Color batteryValueColor(int? pct) {
  if (pct == null) return ColorManager.slate60;
  if (pct < 30) return ColorManager.coralIcon;
  if (pct < 50) return ColorManager.yellowIcon;
  return ColorManager.slate60;
}

/// Device identity tints: the primary device is always sage; other devices
/// keep one stable identity everywhere (coral or yellow) derived from their
/// id, so the colour survives list reorders and app restarts. String.hashCode
/// is deliberately avoided — Dart does not guarantee it stable across runs.
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
