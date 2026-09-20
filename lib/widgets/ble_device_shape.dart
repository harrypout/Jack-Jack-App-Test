import 'package:jackjack/utils/status_colors.dart';
import 'package:flutter/material.dart';

/// The design system's organic device shape: an asymmetric-elliptical
/// border radius over an accent gradient. CSS fraction order is
/// horizontal TL,TR,BR,BL then vertical TL,TR,BR,BL — never rotate it.
const deviceShapeFractionsStandard = [.40, .60, .70, .30, .40, .50, .60, .50];
const deviceShapeFractionsAlt = [.60, .40, .30, .70, .60, .30, .70, .40];
const deviceShapeFractionsOnboarding = [.46, .54, .52, .48, .56, .50, .50, .44];

BorderRadius deviceShapeBorderRadius(
  double width,
  double height, [
  List<double> fractions = deviceShapeFractionsStandard,
]) {
  return BorderRadius.only(
    topLeft: Radius.elliptical(width * fractions[0], height * fractions[4]),
    topRight: Radius.elliptical(width * fractions[1], height * fractions[5]),
    bottomRight: Radius.elliptical(width * fractions[2], height * fractions[6]),
    bottomLeft: Radius.elliptical(width * fractions[3], height * fractions[7]),
  );
}

class BLEDeviceShape extends StatelessWidget {
  final double size;
  final DeviceTone tone;
  final List<double> fractions;
  final List<BoxShadow>? shadow;

  const BLEDeviceShape({
    super.key,
    required this.size,
    this.tone = DeviceTone.sage,
    this.fractions = deviceShapeFractionsStandard,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: tone.gradient,
        borderRadius: deviceShapeBorderRadius(size, size, fractions),
        boxShadow: shadow,
      ),
    );
  }
}
