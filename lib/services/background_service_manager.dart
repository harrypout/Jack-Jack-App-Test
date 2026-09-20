import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/services/alert_recorder.dart';
import 'package:jackjack/services/device_connection.dart';
import 'package:jackjack/services/device_services.dart';
import 'package:jackjack/utils/env_manager.dart';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundServiceManager {
  static final _service = FlutterBackgroundService();
  static int _requestId = 0;

  static Future<void> initialize() async {
    // iOS uses the app's Core Bluetooth central and event-driven wakeups.
    // A background-fetch callback is not a continuous BLE worker.
    if (!Platform.isAndroid) return;
    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'ble_monitoring_service',
            'Device monitoring',
            importance: Importance.low,
          ),
        );
    final configured = await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: 'ble_monitoring_service',
        initialNotificationTitle: 'Jack Jack',
        initialNotificationContent: 'Preparing device monitoring',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );
    if (!configured) {
      throw StateError('Background service could not be configured');
    }
  }

  /// Listen first and repeat an idempotent request until the service is ready.
  /// A timeout never authorizes a second BLE owner to connect.
  static Future<void> request(
    String command, [
    Map<String, dynamic> data = const {},
  ]) async {
    if (!Platform.isAndroid) return;
    final id = '${DateTime.now().microsecondsSinceEpoch}-${++_requestId}';
    final completion = Completer<void>();
    final listener = _service.on('monitorAck').listen((event) {
      if (event?['requestId'] != id || completion.isCompleted) return;
      if (event?['error'] != null) {
        completion.completeError(StateError(event!['error'].toString()));
      } else {
        completion.complete();
      }
    });
    void send() => _service.invoke('monitorCommand', {
      ...data,
      'command': command,
      'requestId': id,
    });
    final retry = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => send(),
    );
    send();
    try {
      await completion.future.timeout(const Duration(seconds: 15));
    } finally {
      retry.cancel();
      await listener.cancel();
    }
  }

  static Future<void> startService() async {
    if (!Platform.isAndroid) return;
    if (!await _service.isRunning() && !await _service.startService()) {
      throw StateError('Background service could not start');
    }
    await request('ping');
  }

  static Future<void> stopService() async {
    if (!Platform.isAndroid || !await _service.isRunning()) return;
    await request('release');
    _service.invoke('stopService');
  }

  static Future<bool> isServiceRunning() async =>
      Platform.isAndroid && await _service.isRunning();

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    final preferences = await SharedPreferences.getInstance();
    await EnvManager.getInstance();
    await NotificationManager.instance.initializePlugin();
    await runWorker(
      service,
      preferences: preferences,
      ble: FlutterReactiveBle(),
    );
  }

  /// Worker logic is shared with integration tests; only native startup above
  /// needs a real Flutter engine. The worker never depends on a UI subscriber.
  static Future<void> runWorker(
    ServiceInstance service, {
    required SharedPreferences preferences,
    required FlutterReactiveBle ble,
  }) async {
    final recorder = AlertRecorder(preferences, reloadBeforeEvent: true);
    final sessions = <String, DeviceConnection>{};
    final devices = <String, BLEDevice>{};
    final alerts = <String, StreamSubscription<int>>{};
    final batteryBusy = <String>{};
    final ready = <String>{};
    final commands = <StreamSubscription>[];
    final completed = <String, Map<String, dynamic>>{};
    final queued = <String>{};
    Future<void> queue = Future.value();

    Future<void> battery(String id) async {
      final device = devices[id];
      if (device == null || !batteryBusy.add(id)) return;
      try {
        await device.getBattery.getValue();
        if (!identical(devices[id], device)) return;
        await recorder.refresh();
        if (!identical(devices[id], device)) return;
        await recorder.battery(
          id,
          device.device.name,
          device.getBattery.data as int,
        );
      } catch (error) {
        debugPrint('Background battery read failed: $error');
      } finally {
        batteryBusy.remove(id);
      }
    }

    Future<void> remove(String id) async {
      await sessions.remove(id)?.stop();
      ready.remove(id);
    }

    Future<void> release() async {
      for (final id in sessions.keys.toList()) {
        await remove(id);
      }
      await recorder.drain();
    }

    void connect(String id, String name) {
      if (sessions.containsKey(id) ||
          preferences.getBool('user_disconnected_$id') == true ||
          preferences.getBool('forgotten_$id') == true) {
        return;
      }
      final description = DiscoveredDevice(
        id: id,
        name: name,
        serviceData: {},
        serviceUuids: [],
        manufacturerData: Uint8List(0),
        rssi: 0,
      );
      var previouslyReady = false;
      var notifyReconnection = false;
      final session = DeviceConnection(
        ble: ble,
        id: id,
        initialize: (isCurrent) async {
          final fresh = await DeviceServices.create(description, ble);
          if (!isCurrent()) {
            await DeviceServices.dispose(fresh);
            return;
          }
          devices[id] = fresh;
          alerts[id] = (fresh.thresholdAlert.data as Stream<int>).listen(
            (flag) async {
              try {
                if (!isCurrent()) return;
                await recorder.refresh();
                if (!isCurrent()) return;
                final event = await recorder.sound(id, name, flag);
                if (event != null) {
                  service.invoke('thresholdAlert', {
                    'deviceId': id,
                    'deviceName': event.device,
                    'handled': true,
                    'createdAt': event.createdAt.toIso8601String(),
                  });
                }
              } catch (error) {
                debugPrint('Background alert failed: $error');
              }
            },
            onError: (Object error) {
              sessions[id]?.recover(error);
            },
            onDone: () {
              if (isCurrent()) {
                sessions[id]?.recover(StateError('Alert subscription ended'));
              }
            },
          );
          unawaited(battery(id));
        },
        release: () async {
          await alerts.remove(id)?.cancel();
          final old = devices.remove(id);
          if (old != null) await DeviceServices.dispose(old);
        },
        onPhase: (phase, error) {
          final monitoring = phase == ConnectionPhase.monitoring;
          if (monitoring) {
            ready.add(id);
          } else {
            ready.remove(id);
          }
          if (monitoring && notifyReconnection) {
            notifyReconnection = false;
            unawaited(
              NotificationManager.instance
                  .showConnectionAlert(
                    deviceId: id,
                    deviceName: name,
                    preferences: preferences,
                  )
                  .catchError((Object error) {
                    debugPrint('$error');
                  }),
            );
          }
          if (previouslyReady && phase == ConnectionPhase.retrying) {
            notifyReconnection = true;
            unawaited(
              NotificationManager.instance
                  .showDisconnectionAlert(
                    deviceId: id,
                    deviceName: name,
                    preferences: preferences,
                  )
                  .catchError((Object e) {
                    debugPrint('$e');
                  }),
            );
          }
          previouslyReady = monitoring;
          if (service is AndroidServiceInstance) {
            unawaited(
              service.setForegroundNotificationInfo(
                title: 'Jack Jack',
                content:
                    '${ready.length} of ${sessions.length} devices connected',
              ),
            );
          }
        },
      );
      sessions[id] = session;
      unawaited(session.start());
    }

    commands.add(
      service.on('monitorCommand').listen((event) {
        final id = event?['requestId'];
        if (id is! String) return;
        if (completed.containsKey(id)) {
          service.invoke('monitorAck', completed[id]);
          return;
        }
        if (!queued.add(id)) return;
        queue = queue.then((_) async {
          final result = <String, dynamic>{'requestId': id};
          try {
            await recorder.refresh();
            switch (event?['command']) {
              case 'acquire':
                final requested = List<String>.from(
                  event?['deviceIds'] as List? ?? [],
                );
                final names = Map<String, String>.from(
                  event?['deviceNames'] as Map? ?? {},
                );
                for (final old in sessions.keys.toList()) {
                  if (!requested.contains(old)) await remove(old);
                }
                for (final next in requested) {
                  connect(next, names[next] ?? 'Pebble');
                }
              case 'release':
                await release();
              case 'ping':
                break;
              default:
                throw StateError('Unknown monitoring command');
            }
          } catch (error) {
            result['error'] = error.toString();
          }
          completed[id] = result;
          queued.remove(id);
          if (completed.length > 50) completed.remove(completed.keys.first);
          service.invoke('monitorAck', result);
        });
      }),
    );
    commands.add(
      service.on('forgetDevice').listen((event) {
        final id = event?['deviceId'];
        if (id is String) {
          queue = queue.then((_) async {
            await recorder.refresh();
            await preferences.setBool('forgotten_$id', true);
            await remove(id);
          });
        }
      }),
    );
    final timer = Timer.periodic(const Duration(seconds: 30), (_) {
      for (final id in ready.toList()) {
        unawaited(battery(id));
      }
    });
    commands.add(
      service.on('stopService').listen((_) async {
        timer.cancel();
        await queue;
        await release();
        for (final listener in commands) {
          await listener.cancel();
        }
        await service.stopSelf();
      }),
    );
  }
}
