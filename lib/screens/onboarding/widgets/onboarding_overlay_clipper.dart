import 'package:flutter/material.dart';

class OnboardingOverlayClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final height = size.height * 0.0;
    Path path = Path();
    path.moveTo(0, height);
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 0.2,
      size.width,
      height,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}