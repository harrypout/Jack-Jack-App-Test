import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BLEBackground extends StatelessWidget {
  final Widget? child;
  const BLEBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Stack(
          children: [
            SvgPicture.asset(
              "assets/svgs/background.svg",
              width: MediaQuery.sizeOf(context).width,
              fit: BoxFit.fill,
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
        child ?? Container(),
      ],
    );
  }
}
