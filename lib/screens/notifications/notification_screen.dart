import 'package:ble/main.dart';
import 'package:ble/providers/notifications_provider.dart';
import 'package:ble/screens/notifications/widgets/notification_group_item.dart';
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
      prefs.getString("notificationsOpened") ??
          DateTime.now().toIso8601String(),
    );

    prefs.setString("notificationsOpened", DateTime.now().toIso8601String());
    final notificationGroups = ref.watch(notificationsProvider);
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...notificationGroups.map(
                        (notificationGroup) => NotificationGroupItem(
                          item: notificationGroup,
                          readTime: readTime,
                        showClearAll: notificationGroup == notificationGroups.first,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
