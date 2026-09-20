import 'dart:async';
import 'package:jackjack/main.dart';
import 'package:jackjack/models/notification_sf.dart';
import 'package:jackjack/services/notification_history.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'notifications_provider.g.dart';

enum NotificationGroupType { today, yesterday, lastWeek, lastMonth }

const notificationGroupTypeToString = {
  NotificationGroupType.today: 'Today',
  NotificationGroupType.yesterday: 'Yesterday',
  NotificationGroupType.lastWeek: 'Last Week',
  NotificationGroupType.lastMonth: 'Last Month',
};

@Riverpod(keepAlive: true)
class Notifications extends _$Notifications {
  @override
  List<NotificationGroupModel> build() {
    // Enforce storage retention on opening history as well as when adding events.
    unawaited(NotificationHistory.prune(prefs).catchError((Object _) => false));
    return getNotifications();
  }

  List<NotificationGroupModel> getNotifications() {
    final groups = <NotificationGroupType, NotificationGroupModel>{};
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    for (final item in NotificationHistory.read(prefs)) {
      final date = item.createdAt.toLocal();
      final days =
          today
              .difference(DateTime.utc(date.year, date.month, date.day))
              .inDays;
      final type =
          days <= 0
              ? NotificationGroupType.today
              : days == 1
              ? NotificationGroupType.yesterday
              : days < 7
              ? NotificationGroupType.lastWeek
              : NotificationGroupType.lastMonth;
      groups
          .putIfAbsent(
            type,
            () => NotificationGroupModel(notifications: [], type: type),
          )
          .notifications
          .add(item);
    }
    return groups.values.toList();
  }

  Future<void> reload() async {
    await prefs.reload();
    await NotificationHistory.prune(prefs);
    state = getNotifications();
  }

  Future<void> addNotification(NotificationSF notification) async {
    final write = NotificationHistory.add(prefs, notification);
    state = getNotifications();
    if (!await write) throw StateError('Could not save notification history');
  }

  Future<void> clearAll() async {
    state = [];
    if (!await prefs.remove('notifications')) {
      throw StateError('Could not clear history');
    }
  }
}

class NotificationGroupModel {
  final List<NotificationSF> notifications;
  final NotificationGroupType type;
  NotificationGroupModel({required this.notifications, required this.type});
}
