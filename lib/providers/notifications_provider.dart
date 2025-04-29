import 'package:ble/main.dart';
import 'package:ble/models/notification_sf.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'notifications_provider.g.dart';


enum NotificationGroupType {
  today,
  yesterday,
  lastWeek,
  lastMonth,
}

Map<NotificationGroupType, String> notificationGroupTypeToString = {
  NotificationGroupType.today: "Today",
  NotificationGroupType.yesterday: "Yesterday",
  NotificationGroupType.lastWeek: "Last Week",
  NotificationGroupType.lastMonth: "Last Month",
};

@Riverpod(keepAlive: true)
class Notifications extends _$Notifications {
  @override
  List<NotificationGroupModel> build() => getNotifications();

  List<NotificationGroupModel> getNotifications() {
        List<String> notificationStrings =
        prefs.getStringList("notifications") ?? [];
    List<NotificationGroupModel> groups = [];
        List<NotificationSF> notifications =  notificationStrings.reversed
        .map((e) => NotificationSF.fromString(e))
        .toList();
    if(notificationStrings.isEmpty) return groups;
    int i = 0;
    while (i < notifications.length) {
      final notification = notifications[i];
      final createdAt = notification.createdAt;
      final now = DateTime.now();
      final difference = now.difference(createdAt);
      NotificationGroupType type;
      if (difference.inDays == 0) {
        type = NotificationGroupType.today;
      } else if (difference.inDays == 1) {
        type = NotificationGroupType.yesterday;
      } else if (difference.inDays < 7) {
        type = NotificationGroupType.lastWeek;
      } else {
        type = NotificationGroupType.lastMonth;
      }
      int index = (){
        final group = groups.firstWhere(
        (g) => g.type == type,
        orElse: () {
          final newGroup = NotificationGroupModel(
            notifications: [],
            type: type,
          );
          groups.add(newGroup);
          return newGroup;
        },
      );
        return groups.indexWhere((indexedGroup) => indexedGroup == group);
        // return 0;
      }();
      groups[index].notifications.add(notification);
      print(groups[index]);
      // group.notifications.add(Notification.fromJson(notification.data()));
      i++;
    }

    return groups;
  }

  void addNotification(NotificationSF notification) {

    // state = [notification, ...state];

    List<String> notificationStrings =
        prefs.getStringList("notifications") ?? [];
    notificationStrings.add(notification.toString());
    prefs.setStringList("notifications", notificationStrings);
    state = getNotifications();
  }

  void clearAll() {
    state = [];
    prefs.remove("notifications");
  }
}

class NotificationGroupModel {
  final List<NotificationSF> notifications;
  final NotificationGroupType type;

  NotificationGroupModel({
    required this.notifications,
    required this.type,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(
        'NotificationGroupModel{type: $type, notificationsCount: ${notifications
            .length}, ');

    if (notifications.isNotEmpty) {
      buffer.write('notifications: [');
      for (var notification in notifications) {
        buffer.write('${notification.toString()}, ');
      }
      buffer.write('], ');
    }

    buffer.write('}');
    return buffer.toString();
  }
}