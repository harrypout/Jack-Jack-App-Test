import 'package:ble/utils/color_manager.dart';
import 'package:flutter/material.dart';

class BLEButton extends StatelessWidget {
  final String data;
  final void Function()? onPressed;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? textColor;
  final Size? buttonSize;
  final bool maxButton;
  final Widget? icon;
  const BLEButton({
    super.key,
    required this.data,
    required this.onPressed,
    this.borderColor,
    this.backgroundColor,
    this.textColor,
    this.buttonSize,
    this.maxButton = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: 8, vertical: maxButton ? 12 : 0),
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: WidgetStateProperty.all(backgroundColor),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        minimumSize:
            maxButton
                ? WidgetStateProperty.all(Size(double.infinity, 55))
                : (buttonSize != null
                    ? WidgetStateProperty.all(buttonSize ?? const Size(146, 44))
                    : WidgetStateProperty.all(Size(80, 45))),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        side: WidgetStateProperty.all(
          BorderSide(color: borderColor ?? ColorManager.secondary, width: 1.0),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      child:
          icon == null
              ? Text(
                data,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor ?? ColorManager.primaryText,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: icon != null ? 8 : 0,
                children: [
                  icon ?? Container(),
                  Text(
                    data,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor ?? ColorManager.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
    );
  }
}
