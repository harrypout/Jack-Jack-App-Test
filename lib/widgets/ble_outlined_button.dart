import 'package:ble/utils/color_manager.dart';
import 'package:ble/widgets/ble_button.dart';
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
      // backgroundColor: ColorManager.white,
      borderColor: borderColor ?? buttonColor,
      textColor: textColor ?? ColorManager.accent,
      buttonSize: buttonSize,
      maxButton: maxButton,
      icon: icon,
    );
  }
}