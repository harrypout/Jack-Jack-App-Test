import 'package:ble/main.dart';
import 'package:ble/providers/notifications_provider.dart';
import 'package:ble/screens/notifications/widgets/notification_item.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:ble/widgets/ble_app_bar.dart';
import 'package:ble/widgets/ble_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class NotificationScreen extends ConsumerWidget {
  static const String id = 'notification_screen';
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime readTime = DateTime.parse(
      prefs.getString("notificationsOpened") ?? DateTime.now().toIso8601String(),
    );
    prefs.setString("notificationsOpened", DateTime.now().toIso8601String());
    final notificationGroups = ref.watch(notificationsProvider);
    final flattenedItems = _flattenNotifications(notificationGroups);

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
                onLeadingTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: flattenedItems.length,
                  itemBuilder: (context, index) {
                    final item = flattenedItems[index];

                    if (item is NotificationHeaderItem) {
                      return _buildHeader(
                        context,
                        ref,
                        item.groupType,
                        item.showClearAll
                      );
                    } else if (item is NotificationContentItem) {
                      return NotificationItem(
                        key: ValueKey(item.notification.id),
                        item: item.notification,
                        readTime: readTime,
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, NotificationGroupType type, bool showClearAll) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ThemeManager.horizontalPadding),
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              notificationGroupTypeToString[type]!.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: ColorManager.tertiaryText,
              ),
            ),
            if (showClearAll)
              TextButton(
                onPressed: () {
                  ref.read(notificationsProvider.notifier).clearAll();
                  ref.invalidate(notificationsProvider);
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
    );
  }

  List<NotificationListItem> _flattenNotifications(List<NotificationGroupModel> groups) {
    List<NotificationListItem> items = [];

    for (int i = 0; i < groups.length; i++) {
      items.add(NotificationHeaderItem(
        groupType: groups[i].type,
        showClearAll: i == 0,
      ));
      for (var notification in groups[i].notifications) {
        items.add(NotificationContentItem(notification: notification));
      }
    }

    return items;
  }
}

abstract class NotificationListItem {}

class NotificationHeaderItem extends NotificationListItem {
  final NotificationGroupType groupType;
  final bool showClearAll;

  NotificationHeaderItem({required this.groupType, this.showClearAll = false});
}

class NotificationContentItem extends NotificationListItem {
  final dynamic notification;
  NotificationContentItem({required this.notification});
}
