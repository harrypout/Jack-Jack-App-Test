import 'dart:async';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:jackjack/main.dart';
import 'package:jackjack/providers/alert_clock_provider.dart';
import 'package:jackjack/providers/last_recorded_alert_provider.dart';
import 'package:jackjack/providers/notifications_provider.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/services/alert_recorder.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'threshold_alert_provider.g.dart';

@Riverpod(keepAlive: true)
class ThresholdAlert extends _$ThresholdAlert {
  final Map<String, StreamSubscription<int>> _subscriptions = {};
  final Map<String, Stream<int>> _sources = {};
  final List<StreamSubscription> _background = [];
  bool _disposed = false;
  late AlertRecorder _recorder;

  @override
  void build() {
    _disposed = false;
    _recorder = AlertRecorder(prefs, now: ref.read(alertClockProvider));
    for (final channel in [
      'thresholdAlert',
      'deviceDisconnected',
      'deviceConnected',
    ]) {
      _background.add(
        FlutterBackgroundService()
            .on(channel)
            .listen(
              (event) async {
                if (_disposed || event == null) return;
                final id = event['deviceId'];
                if (id is! String ||
                    prefs.getBool('user_disconnected_$id') == true ||
                    prefs.getBool('forgotten_$id') == true) {
                  return;
                }
                if (event['handled'] == true) {
                  await ref.read(notificationsProvider.notifier).reload();
                  if (!_disposed && channel == 'thresholdAlert') {
                    ref.read(lastRecordedAlertProvider(id).notifier).state =
                        DateTime.tryParse(event['createdAt'] as String? ?? '');
                  }
                  return;
                }
                // Compatibility with events emitted by an older service while the app
                // updates. New Android service records and delivers before emitting.
                if (channel == 'deviceDisconnected') {
                  try {
                    await NotificationManager.instance.showDisconnectionAlert(
                      deviceId: id,
                      deviceName: event['deviceName'] as String? ?? id,
                    );
                  } catch (error) {
                    debugPrint('Connection notification failed: $error');
                  }
                } else if (channel == 'deviceConnected') {
                  try {
                    await NotificationManager.instance.showConnectionAlert(
                      deviceId: id,
                      deviceName: event['deviceName'] as String? ?? id,
                    );
                  } catch (error) {
                    debugPrint('Connection notification failed: $error');
                  }
                }
                if (channel == 'thresholdAlert' && event['threshold'] is int) {
                  await record(
                    id,
                    event['deviceName'] as String? ?? id,
                    event['threshold'] as int,
                  );
                }
              },
              onError: (Object error) {
                debugPrint('Background event error: $error');
              },
            ),
      );
    }
    ref.onDispose(() {
      _disposed = true;
      for (final subscription in _background) {
        unawaited(subscription.cancel());
      }
      _background.clear();
      for (final id in _subscriptions.keys.toList()) {
        cancelDevice(id);
      }
    });
  }

  Future<void> record(String id, String name, int flag) async {
    try {
      final event = await _recorder.sound(id, name, flag);
      if (_disposed || event == null) return;
      ref.read(lastRecordedAlertProvider(id).notifier).state = event.createdAt;
      ref.invalidate(notificationsProvider);
    } catch (error) {
      debugPrint('Alert delivery failed: $error');
    }
  }

  Future<void> battery(String id, String name, int value) async {
    try {
      final event = await _recorder.battery(id, name, value);
      if (!_disposed && event != null) ref.invalidate(notificationsProvider);
    } catch (error) {
      debugPrint('Battery alert failed: $error');
    }
  }

  Future<void> drain() => _recorder.drain();

  void cancelDevice(String id) {
    unawaited(_subscriptions.remove(id)?.cancel());
    _sources.remove(id);
  }

  void setupAlerts() {
    final devices = ref.read(connectedDevicesProvider);
    for (final id in _subscriptions.keys.toList()) {
      if (!devices.containsKey(id)) cancelDevice(id);
    }
    for (final id in devices.keys) {
      setupDeviceAlert(id);
    }
  }

  void setupDeviceAlert(String id) {
    final device = ref.read(connectedDevicesProvider)[id];
    final stream = device?.thresholdAlert.data;
    if (stream is! Stream<int> ||
        device?.thresholdAlert.qualifiedCharacteristic == null) {
      cancelDevice(id);
      return;
    }
    if (identical(_sources[id], stream)) return;
    cancelDevice(id);
    _sources[id] = stream;
    _subscriptions[id] = stream.listen(
      (value) {
        if (_disposed ||
            !identical(ref.read(connectedDevicesProvider)[id], device)) {
          return;
        }
        unawaited(record(id, device!.device.name, value));
      },
      onError: (Object error) {
        if (!_disposed &&
            identical(ref.read(connectedDevicesProvider)[id], device)) {
          ref.read(connectedDevicesProvider.notifier).recover(id, error);
        }
      },
      onDone: () {
        if (!_disposed && identical(_sources[id], stream)) {
          ref
              .read(connectedDevicesProvider.notifier)
              .recover(id, StateError('Alert stream ended'));
        }
      },
    );
  }
}
