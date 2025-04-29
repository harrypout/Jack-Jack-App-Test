import 'package:ble/providers/notifications_provider.dart';
import 'package:ble/screens/notifications/widgets/notification_item.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationGroupItem extends ConsumerWidget {
  final NotificationGroupModel item;
  final DateTime readTime;
  final bool showClearAll;
  const NotificationGroupItem({
    super.key,
    required this.item,
    required this.readTime,
    this.showClearAll = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ThemeManager.horizontalPadding,
              ),
              child: SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notificationGroupTypeToString[item.type]!.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: ColorManager.tertiaryText,
                      ),
                    ),
                    if (showClearAll)
                      TextButton(
                        onPressed: () async {
                          ref.read(notificationsProvider.notifier).clearAll();
                          ref.refresh(notificationsProvider);
                        },
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
            ),
            ...item.notifications.map(
              (notification) => NotificationItem(
                item: notification,
                readTime: readTime,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
