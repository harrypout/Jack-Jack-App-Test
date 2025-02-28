import 'package:ble/screens/notifications/widgets/notification_item.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:ble/widgets/ble_app_bar.dart';
import 'package:ble/widgets/ble_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NotificationScreen extends StatelessWidget {
  static const String id = 'notification_screen';
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BLEBackground(
        child: SafeArea(
          child: Column(
            children: [
              BLEAppBar(
                title: "Notifications",
                leading: SvgPicture.asset(
                  "assets/svgs/arrow-left.svg",
                  width: 24,
                  height: 24,
                  fit: BoxFit.scaleDown,
                ),
                onLeadingTap: () {
                  Navigator.pop(context);
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ThemeManager.horizontalPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today".toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: ColorManager.tertiaryText,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Clear All",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: ColorManager.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              NotificationItem(
                title: "Threshold Exceeded!",
                desc: "Current Sound Level: 85 dB, Detected by SoundSense ",
                time: DateTime.now(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
