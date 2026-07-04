import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/widgets/ble_button.dart';
import 'package:flutter/material.dart';

class BLEOutlinedButton extends StatelessWidget {
  final String data;
  final void Function()? onPressed;
  final Color? buttonColor;
  final Color? textColor;
  final Color? borderColor;
  final Size? buttonSize;
  final bool maxButton;
  final Widget? icon;
  const BLEOutlinedButton({
    super.key,
    required this.data,
    required this.onPressed,
    this.buttonColor,
    this.textColor,
    this.borderColor,
    this.buttonSize,
    this.maxButton = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return BLEButton(
      data: data,
      onPressed: onPressed,
      backgroundColor: buttonColor ?? ColorManager.white,
      borderColor: borderColor ?? ColorManager.slate10,
      textColor: textColor ?? ColorManager.slate70,
      buttonSize: buttonSize,
      maxButton: maxButton,
      icon: icon,
    );
  }
}
