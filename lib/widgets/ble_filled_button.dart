import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_button.dart';
import 'package:flutter/material.dart';

class BLEFilledButton extends StatelessWidget {
  final String data;
  final Size? buttonSize;
  final void Function()? onPressed;
  final bool maxButton;
  final Color? buttonColor;
  final Widget? icon;
  const BLEFilledButton({
    super.key,
    required this.data,
    this.buttonSize,
    required this.onPressed,
    this.maxButton = false,
    this.buttonColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: ThemeManager.brFull,
        // Sage CTA glow, only while the button is enabled.
        boxShadow: onPressed != null ? ThemeManager.sageGlow : null,
      ),
      child: BLEButton(
        key: key,
        data: data,
        buttonSize: buttonSize,
        onPressed: onPressed,
        maxButton: maxButton,
        backgroundColor: buttonColor ?? ColorManager.accent,
        textColor: ColorManager.white,
        borderColor: buttonColor ?? ColorManager.accent,
        icon: icon,
      ),
    );
  }
}
