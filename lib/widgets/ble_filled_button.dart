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
  // The sage CTA glow marks the recommended action — turn it off for
  // destructive buttons so they don't read as the primary choice.
  final bool glow;
  const BLEFilledButton({
    super.key,
    required this.data,
    this.buttonSize,
    required this.onPressed,
    this.maxButton = false,
    this.buttonColor,
    this.icon,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: ThemeManager.brFull,
        boxShadow: glow && onPressed != null ? ThemeManager.sageGlow : null,
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
