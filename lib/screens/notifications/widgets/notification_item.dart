import 'package:ble/utils/color_manager.dart';
import 'package:ble/widgets/ble_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationItem extends StatelessWidget {
  final String title;
  final String desc;
  final DateTime time;
  final bool unread;

  const NotificationItem({
    super.key,
    required this.title,
    required this.desc,
    required this.time,
    this.unread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Ensure it takes full width
      height: 75,
      padding: const EdgeInsets.all(14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ColorManager.white,
        border: Border(bottom: BorderSide(color: Color(0xFFECEDF3))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorManager.secondary,
            ),
            child: SvgPicture.asset(
              "assets/svgs/notification.svg",
              width: 20,
              height: 20,
              fit: BoxFit.scaleDown,
            ),
          ),
          const SizedBox(
            width: 12,
          ), // Add spacing instead of `spacing` property
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        spacing: 8,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: ColorManager.primaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          BLEPill(color: Colors.red),
                        ],
                      ),
                    ),
                    Text(
                      timeago.format(time),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: ColorManager.tertiaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: ColorManager.secondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}