import 'package:jackjack/models/notification_sf.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage is oldest first for compatibility; presentation is newest first.
/// Every record is parsed independently so one damaged entry cannot hide the rest.
class NotificationHistory {
  static List<NotificationSF> read(
    SharedPreferences preferences, {
    DateTime? now,
    List<String>? rawRecords,
  }) {
    final cutoff = (now ?? DateTime.now()).subtract(const Duration(days: 30));
    final records = <NotificationSF>[];
    final ids = <String>{};
    for (final raw
        in (rawRecords ?? preferences.getStringList('notifications') ?? [])
            .reversed) {
      try {
        final item = NotificationSF.fromString(raw);
        if (!item.createdAt.isBefore(cutoff) && ids.add(item.id)) {
          records.add(item);
        }
      } on Object {
        /* Skip just this invalid record. */
      }
    }
    // Keep insertion order for simultaneous events.
    final indexed =
        records.indexed.toList()..sort((a, b) {
          final order = b.$2.createdAt.compareTo(a.$2.createdAt);
          return order == 0 ? a.$1.compareTo(b.$1) : order;
        });
    return indexed.take(1000).map((entry) => entry.$2).toList();
  }

  static Future<bool> prune(SharedPreferences preferences, {DateTime? now}) =>
      preferences.setStringList(
        'notifications',
        read(preferences, now: now).reversed.map((e) => e.toString()).toList(),
      );

  static Future<bool> add(SharedPreferences preferences, NotificationSF event) {
    final raw = preferences.getStringList('notifications') ?? [];
    final records = read(preferences, rawRecords: [...raw, event.toString()]);
    return preferences.setStringList(
      'notifications',
      records.reversed.map((e) => e.toString()).toList(),
    );
  }
}
