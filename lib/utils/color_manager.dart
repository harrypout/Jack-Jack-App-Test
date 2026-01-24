import 'package:flutter/material.dart';

class ColorManager {
  // Base colors
  static const white = Colors.white;
  static const black = Colors.black;
  static const transparent = Colors.transparent;

  // Primary colors
  static const background = Color(0xfffdfbf7);
  static const accent = Color(0xFF8eb8a8);

  // Accent-derived colors (change automatically when accent changes)
  static final accentDisabled = accent.withValues(alpha: 0.5);
  static final secondary = accent.withValues(alpha: 0.1);
  static final selectedContainerBorder = accent.withValues(alpha: 0.4);
  static final selectedContainerBackground = accent.withValues(alpha: 0.05);
  static final inactiveGauge = accent.withValues(alpha: 0.3);

  // Text colors
  static const primaryText = Color(0xFF101828);
  static const secondaryText = Color(0xFF475467);
  static const tertiaryText = Color(0xFF667085);
  static const quaternaryText = Color(0xFF344054);
  static const gaugeAxisLabelText = Color(0xFF98A2B3);

  // Container colors
  static const containerBorder = Color(0xffF2F4F7);
  static const greyContainerBackground = Color(0xffF9FAFB);

  // Misc
  static const pill = Color(0xffD0D5DD);

  // Status colors (derived from accent for consistency)
  static final success = HSLColor.fromColor(accent).withHue(120).toColor();
  static final error = HSLColor.fromColor(accent).withHue(0).toColor();
  static final warning = HSLColor.fromColor(accent).withHue(45).toColor();

  // Shadow color
  static final shadow = black.withValues(alpha: 0.1);
}
