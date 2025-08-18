import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';

class BLEBottomSheet extends StatelessWidget {
  final Widget? child;
  const BLEBottomSheet({super.key, this.child});

  static Future<void> openSheet(
    BuildContext context,
    Widget bottomSheet, {
    bool isScrollControlled = false,
  }) async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: isScrollControlled,
        builder: (BuildContext context) => bottomSheet);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: ColorManager.containerBorder,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          SafeArea(
            child: Container(
              padding: EdgeInsets.all(ThemeManager.horizontalPadding),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
