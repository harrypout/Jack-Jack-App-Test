import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:jackjack/models/notification_sf.dart';
import 'package:jackjack/services/notification_history.dart';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Used by both BLE owners. Persisted per-device state survives app/service
/// handoffs and relaunches; the firmware's 120-second latch remains unchanged.
class AlertRecorder {
  final SharedPreferences preferences;
  final DateTime Function() now;
  final bool reloadBeforeEvent;
  Future<void> _pending = Future.value();
  AlertRecorder(
    this.preferences, {
    DateTime Function()? now,
    this.reloadBeforeEvent = false,
  }) : now = now ?? DateTime.now;

  Future<void> drain() => _pending;
  Future<void> refresh() async {
    await _serialize(() async {
      await preferences.reload();
      return null;
    });
  }

  Future<void> _deliver(Future<void> Function() show) async {
    try {
      await show();
      await preferences.remove('notification_delivery_error');
    } catch (error) {
      // History remains available even if the operating system rejects delivery.
      await preferences.setString(
        'notification_delivery_error',
        error.toString(),
      );
      debugPrint('Phone notification failed: $error');
    }
  }

  bool _allowed(String id) =>
      preferences.getBool('user_disconnected_$id') != true &&
      preferences.getBool('forgotten_$id') != true;
  String _name(String id, String fallback) {
    try {
      return (jsonDecode(preferences.getString('device_names') ?? '{}')
                  as Map)[id]
              as String? ??
          fallback;
    } on Object {
      return fallback;
    }
  }

  Future<NotificationSF?> _serialize(
    Future<NotificationSF?> Function() action,
  ) {
    final result = _pending.then((_) async {
      if (reloadBeforeEvent) await preferences.reload();
      return action();
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<NotificationSF?> sound(String id, String name, int flag) =>
      _serialize(() async {
        if (flag != 1 || !_allowed(id)) return null;
        final time = now();
        final last = DateTime.tryParse(
          preferences.getString('last_alert_$id') ?? '',
        );
        final seconds =
            const {
              '15 seconds': 15,
              '30 seconds': 30,
              '1 minute': 60,
              '2 minutes': 120,
            }[preferences.getString('notificationTimeout')] ??
            15;
        final elapsed = last == null ? null : time.difference(last);
        if (elapsed != null &&
            !elapsed.isNegative &&
            elapsed < Duration(seconds: seconds)) {
          return null;
        }
        final event = NotificationSF(
          deviceId: id,
          device: _name(id, name),
          value: 1,
          createdAt: time,
        );
        if (!await NotificationHistory.add(preferences, event)) {
          throw StateError('Could not save alert');
        }
        await preferences.setString('last_alert_$id', time.toIso8601String());
        if (_allowed(id)) {
          await _deliver(
            () => NotificationManager.instance.showThresholdAlert(
              deviceId: id,
              deviceName: event.device,
              threshold: flag,
              preferences: preferences,
            ),
          );
        }
        return event;
      });

  Future<NotificationSF?> battery(String id, String name, int value) =>
      _serialize(() async {
        if (!_allowed(id) || value < 0 || value > 100) return null;
        final key = 'low_battery_$id';
        if (value >= 25) {
          await preferences.remove(key);
          return null;
        }
        if (value >= 20 || preferences.getBool(key) == true) return null;
        final event = NotificationSF(
          deviceId: id,
          device: _name(id, name),
          value: value,
          kind: 'battery',
          createdAt: now(),
        );
        if (!await NotificationHistory.add(preferences, event)) {
          throw StateError('Could not save battery warning');
        }
        await preferences.setBool(key, true);
        if (_allowed(id)) {
          await _deliver(
            () => NotificationManager.instance.showLowBatteryAlert(
              deviceId: id,
              deviceName: event.device,
              battery: value,
              preferences: preferences,
            ),
          );
        }
        return event;
      });
}
