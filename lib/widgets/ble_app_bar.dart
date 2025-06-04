import 'package:jackjack/utils/color_manager.dart';
import 'package:flutter/material.dart';

class BLEAppBar extends StatelessWidget {
  static Size size = const Size(double.infinity, 50);
  final Widget? leading;
  final void Function()? onLeadingTap;
  final String? title;
  final Widget? trailing;
  final void Function()? onTrailingTap;
  final Color titleColor;
  const BLEAppBar({
    super.key,
    this.leading,
    this.onLeadingTap,
    this.title,
    this.trailing,
    this.onTrailingTap,
    this.titleColor = ColorManager.primaryText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: SafeArea(
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(

                  onPressed: leading != null ? onLeadingTap : null,
                  icon: leading ?? Container(),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Center(
                      child: Text(
                        title ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                trailing != null
                    ? IconButton(
                      onPressed: trailing != null ? onTrailingTap : null,
                      icon: trailing ?? Container(),
                    )
                    : Container(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
