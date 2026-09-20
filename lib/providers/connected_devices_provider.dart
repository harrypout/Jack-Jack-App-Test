import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jackjack/main.dart';
import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/providers/loading_provider.dart';
import 'package:jackjack/providers/paired_devices.dart';
import 'package:jackjack/providers/threshold_alert_provider.dart';
import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:jackjack/services/device_connection.dart';
import 'package:jackjack/services/device_services.dart';
import 'package:jackjack/services/device_name_manager.dart';
import 'package:jackjack/utils/notification_manager.dart';
import 'package:jackjack/utils/toast_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'connected_devices_provider.g.dart';

final bleClientProvider = Provider<FlutterReactiveBle>(
  (ref) => FlutterReactiveBle(),
);
final connectionDesiredProvider = StateProvider.family<bool, String>(
  (ref, id) => false,
);
final connectionErrorProvider = StateProvider.family<String?, String>(
  (ref, id) => null,
);

@Riverpod(keepAlive: true)
class ConnectedDevices extends _$ConnectedDevices {
  final Map<String, DiscoveredDevice> _desired = {};
  Map<String, DiscoveredDevice> get desiredDevices =>
      Map.unmodifiable(_desired);
  final Map<String, DeviceConnection> _connections = {};
  final Map<String, StreamSubscription<int>> _levels = {};
  final Map<String, Future<bool>> _requests = {};
  final Map<String, int> _revisions = {};
  final Set<String> _batteryReads = {};
  bool _disposed = false;
  bool _suspended = false;

  @override
  Map<String, BLEDevice> build() {
    ref.onDispose(() {
      _disposed = true;
      for (final connection in _connections.values) {
        unawaited(connection.stop());
      }
      for (final subscription in _levels.values) {
        unawaited(subscription.cancel());
      }
    });
    return {};
  }

  void playAudio() {
    throw UnsupportedError('Live listening is unavailable with this firmware');
  }

  Future<void> stopAudio() async {}

  Future<void> removeDevice(String id) async {
    _desired.remove(id);
    ref.read(connectionDesiredProvider(id).notifier).state = false;
    _revisions[id] = (_revisions[id] ?? 0) + 1;
    await prefs.setBool('forgotten_$id', true);
    await prefs.setBool('user_disconnected_$id', true);
    FlutterBackgroundService().invoke('forgetDevice', {'deviceId': id});
    ref.read(thresholdAlertProvider.notifier).cancelDevice(id);
    final device = state[id];
    state = {...state}..remove(id);
    await _connections.remove(id)?.stop();
    await _levels.remove(id)?.cancel();
    if (device != null) await DeviceServices.dispose(device);
    ref.read(connectedDevicesTrackerProvider.notifier).markDisconnected(id);
    await PairedDevicesUUID.removeFromPrefs(id);
    await DeviceNameManager.instance.removeDeviceName(id);
    for (final key in [
      '${id}s',
      '${id}v',
      'last_alert_$id',
      'low_battery_$id',
    ]) {
      await prefs.remove(key);
    }
  }

  Future<bool> connect(
    DiscoveredDevice device, {
    Duration timeout = const Duration(seconds: 20),
    bool shouldConnect = true,
  }) {
    if (shouldConnect) {
      _desired[device.id] = device;
    } else {
      _desired.remove(device.id);
    }
    ref.read(connectionDesiredProvider(device.id).notifier).state =
        shouldConnect;
    if (shouldConnect && _requests.containsKey(device.id)) {
      return _requests[device.id]!;
    }
    final revision = _revisions[device.id] ?? 0;
    final result = _connect(
      device,
      timeout: timeout,
      shouldConnect: shouldConnect,
      revision: revision,
    );
    _requests[device.id] = result;
    result.whenComplete(() {
      if (identical(_requests[device.id], result)) _requests.remove(device.id);
    }).ignore();
    return result;
  }

  Future<bool> _connect(
    DiscoveredDevice device, {
    Duration timeout = const Duration(seconds: 20),
    bool shouldConnect = true,
    required int revision,
  }) async {
    final id = device.id;
    if (!shouldConnect) {
      _revisions[id] = (_revisions[id] ?? 0) + 1;
      await prefs.setBool('user_disconnected_$id', true);
      await _connections.remove(id)?.stop();
      return true;
    }
    if (_suspended) return false;
    if (_connections.containsKey(id)) {
      return ref
          .read(connectedDevicesTrackerProvider.notifier)
          .isDeviceConnected(id);
    }
    await prefs.remove('forgotten_$id');
    if (_disposed || revision != (_revisions[id] ?? 0)) return false;
    await prefs.remove('user_disconnected_$id');
    if (_disposed || revision != (_revisions[id] ?? 0)) return false;
    if (!state.containsKey(id)) await getServices(device, shouldConnect: false);
    if (_disposed || _suspended || revision != (_revisions[id] ?? 0)) {
      return false;
    }
    final ble = ref.read(bleClientProvider);
    var wasMonitoring = false;
    BLEDevice? owned;
    late DeviceConnection connection;
    connection = DeviceConnection(
      ble: ble,
      id: id,
      timeout: timeout,
      initialize: (isCurrent) async {
        final fresh = await DeviceServices.create(device, ble);
        if (!isCurrent() || _disposed) {
          await DeviceServices.dispose(fresh);
          return;
        }
        owned = fresh;
        state = {...state, id: fresh};
        ref.read(thresholdAlertProvider.notifier).setupDeviceAlert(id);
        await PairedDevicesUUID.saveToPrefs(id);
        await prefs.setString('advertised_name_$id', device.name);
        if (!isCurrent() || _disposed) return;
        _levels[id] = (fresh.getSoundLevel.data as Stream<int>).listen(
          (_) {},
          onError: (Object error) {
            recover(id, error);
          },
        );
        unawaited(refreshBattery(id));
      },
      release: () async {
        if (_disposed) return;
        ref.read(thresholdAlertProvider.notifier).cancelDevice(id);
        await _levels.remove(id)?.cancel();
        final old = owned;
        owned = null;
        if (old != null) {
          await DeviceServices.dispose(old);
          if (!_disposed && identical(state[id], old)) state = {...state};
        }
      },
      onPhase: (phase, error) {
        if (_disposed) return;
        final ready = phase == ConnectionPhase.monitoring;
        ref
            .read(loadingProvider(id).notifier)
            .toggle(phase == ConnectionPhase.connecting);
        ref.read(connectionErrorProvider(id).notifier).state =
            error?.toString();
        final tracker = ref.read(connectedDevicesTrackerProvider.notifier);
        if (ready) {
          tracker.markConnected(id);
        } else {
          tracker.markDisconnected(id);
        }
        if (ready && !wasMonitoring) {
          unawaited(
            NotificationManager.instance
                .showConnectionAlert(
                  deviceId: id,
                  deviceName: DeviceNameManager.instance.getDisplayName(
                    id,
                    device.name,
                  ),
                )
                .catchError((Object error) {
                  debugPrint('$error');
                }),
          );
        } else if (wasMonitoring && phase == ConnectionPhase.retrying) {
          unawaited(
            NotificationManager.instance
                .showDisconnectionAlert(
                  deviceId: id,
                  deviceName: DeviceNameManager.instance.getDisplayName(
                    id,
                    device.name,
                  ),
                )
                .catchError((Object error) {
                  debugPrint('$error');
                }),
          );
        }
        wasMonitoring = ready;
      },
    );
    _connections[id] = connection;
    final ready = await connection.start();
    if (!ready && !_disposed) {
      ToastManager.show(
        'Connection unavailable. Jack Jack will retry while this device is enabled.',
      );
    }
    return ready;
  }

  void recover(String id, Object error) {
    _connections[id]?.recover(error);
  }

  Future<void> getServices(
    DiscoveredDevice device, {
    bool shouldConnect = true,
  }) async {
    if (shouldConnect) {
      await connect(device);
      return;
    }
    if (state.containsKey(device.id)) return;
    final revision = _revisions[device.id] ?? 0;
    final model = await DeviceServices.create(
      device,
      ref.read(bleClientProvider),
      connected: false,
    );
    if (!_disposed &&
        !state.containsKey(device.id) &&
        revision == (_revisions[device.id] ?? 0) &&
        prefs.getBool('forgotten_${device.id}') != true) {
      state = {...state, device.id: model};
    } else {
      await DeviceServices.dispose(model);
    }
  }

  Future<void> refreshBattery(String id) async {
    final device = state[id];
    if (device == null ||
        device.getBattery.qualifiedCharacteristic == null ||
        !_batteryReads.add(id)) {
      return;
    }
    try {
      await device.getBattery.getValue();
      if (_disposed || !identical(state[id], device)) return;
      final value = device.getBattery.data;
      if (value is! int || value < 0 || value > 100) {
        throw StateError('Invalid battery reading');
      }
      state = {...state};
      await ref
          .read(thresholdAlertProvider.notifier)
          .battery(id, device.device.name, value);
    } catch (error) {
      if (!_disposed && identical(state[id], device)) {
        device.getBattery.data = null;
        state = {...state};
      }
    } finally {
      _batteryReads.remove(id);
    }
  }

  Future<void> suspend() async {
    _suspended = true;
    final sessions = _connections.values.toList();
    _connections.clear();
    for (final session in sessions) {
      await session.stop();
    }
    await ref.read(thresholdAlertProvider.notifier).drain();
  }

  Future<void> resume() async {
    _suspended = false;
    for (final device in _desired.values.toList()) {
      if (prefs.getBool('user_disconnected_${device.id}') != true &&
          prefs.getBool('forgotten_${device.id}') != true) {
        unawaited(connect(device));
        unawaited(refreshBattery(device.id));
      }
    }
  }
}
