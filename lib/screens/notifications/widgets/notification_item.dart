import 'package:ble/models/notification_sf.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:ble/widgets/ble_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationItem extends StatelessWidget {
  final NotificationSF item;
  final DateTime readTime;

  const NotificationItem({super.key, required this.item,
    required this.readTime,});

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
                            "Threshold Exceeded!",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: ColorManager.primaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (readTime.isBefore(item.createdAt))
                            BLEPill(color: Colors.red),

                        ],
                      ),
                    ),
                    Text(
                      timeago.format(item.createdAt),
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
                  "Current Sound Level: ${item.value} dB, Detected by ${item.device} ",
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
