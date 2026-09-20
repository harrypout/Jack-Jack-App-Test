import 'package:flutter/material.dart';

/// Design-system colour tokens (design_handoff_jackjack_redesign).
/// Legacy names are kept and retargeted so existing call sites pick up the
/// new palette without edits; all members are const because they appear in
/// const TextStyle/BoxDecoration contexts throughout the app.
class ColorManager {
  // Base colors
  static const white = Colors.white;
  static const black = Colors.black;
  static const transparent = Colors.transparent;

  // Brand palette
  static const background = Color(0xFFFDFBF7); // warm off-white page bg
  static const sage = Color(0xFF8EB8A8); // primary accent
  static const coral = Color(0xFFE8A89C); // alerts / streaming / selection
  static const yellow = Color(0xFFF4D35E); // badges / warnings
  static const slate = Color(0xFF4A5568); // primary text

  static const accent = sage;

  // Icon/dot-strength accent variants (legible small foregrounds)
  static const coralIcon = Color(0xFFC77A6C);
  static const coralDot = Color(0xFFD98A7C);
  static const yellowIcon = Color(0xFFB99114);
  static const yellowDot = Color(0xFFE5C13D);

  // Slate opacity ramp (alpha-encoded const so const contexts keep working)
  static const slate90 = Color(0xE64A5568);
  static const slate80 = Color(0xCC4A5568);
  static const slate70 = Color(0xB34A5568); // secondary body
  static const slate60 = Color(0x994A5568); // captions / icons
  static const slate20 = Color(0x334A5568); // input borders, separators
  static const slate10 = Color(0x1A4A5568); // nav rule, button borders
  static const slate05 = Color(0x0D4A5568); // card hairlines

  // Accent tint fills (icon blocks, pills, callouts)
  static const sageTint10 = Color(0x1A8EB8A8);
  static const sageTint20 = Color(0x338EB8A8);
  static const sageTint50 = Color(0x808EB8A8);
  static const coralTint10 = Color(0x1AE8A89C);
  static const coralTint20 = Color(0x33E8A89C);
  static const yellowTint10 = Color(0x1AF4D35E);
  static const yellowTint20 = Color(0x33F4D35E);

  // Jack Jack-blob gradient stops
  static const sageGradStart = Color(0xFFA6C7BA);
  static const sageGradEnd = Color(0xFF6E9E8D);
  static const coralGradStart = Color(0xFFF0C3BA);
  static const coralGradEnd = Color(0xFFD98A7C);

  // Accent-derived colors
  static const accentDisabled = sageTint50;
  static const secondary = sageTint10;
  static const selectedContainerBorder = sageTint50;
  static const selectedContainerBackground = sageTint10;
  static const inactiveGauge = sageTint20; // gauge remainder arc

  // Text colors (legacy roles → slate ramp)
  static const primaryText = slate;
  static const secondaryText = slate80;
  static const tertiaryText = slate60;
  static const quaternaryText = slate90;
  static const gaugeAxisLabelText = slate60;

  // Container colors
  static const containerBorder = slate05;
  static const greyContainerBackground = white; // card surfaces are white

  // Misc
  static const pill = slate20;

  // Status colors. error is icon-strength coral: its consumers are small
  // foreground marks (the unread dot), and the design's rule is that dots
  // and icons use the darker accent variants for legibility.
  static const success = sage;
  static const error = coralIcon;
  static const warning = yellow;

  // Shadow color
  static const shadow = slate10;
}
