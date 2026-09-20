import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:jackjack/main.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/providers/paired_devices.dart';
import 'package:jackjack/services/app_initializer.dart';
import 'package:jackjack/services/app_lifecycle_manager.dart';
import 'package:jackjack/utils/env_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'available_devices.g.dart';

@Riverpod(keepAlive: true)
class DeviceManager extends _$DeviceManager {
  StreamSubscription<DiscoveredDevice>? _scan;
  Timer? _cycle;
  Timer? _restart;
  bool _stopped = false;
  bool _disposed = false;
  int _generation = 0;
  final Map<String, DiscoveredDevice> _discovered = {};

  @override
  BLEDevices build() {
    _disposed = false;
    ref.listen(appInitializerProvider, (_, _) => refreshScan());
    ref.listen(bleStatusNotifierProvider, (_, _) => refreshScan());
    ref.listen(connectedDevicesProvider, (_, _) => updateDeviceStreams());
    ref.onDispose(() {
      _disposed = true;
      stopScan();
    });
    Future.microtask(() {
      if (!_disposed) refreshScan();
    });
    return BLEDevices(available: [], paired: []);
  }

  void updateDeviceStreams() {
    if (_disposed) return;
    final ids = PairedDevicesUUID.getList;
    final paired = <DiscoveredDevice>[];
    for (final id in ids) {
      final device =
          _discovered[id] ??
          ref.read(connectedDevicesProvider)[id]?.device ??
          DiscoveredDevice(
            id: id,
            name: prefs.getString('advertised_name_$id') ?? 'Pebble',
            serviceData: {},
            serviceUuids: [],
            manufacturerData: Uint8List(0),
            rssi: 0,
          );
      paired.add(device);
      if (!ref.read(connectedDevicesProvider).containsKey(id)) {
        unawaited(
          ref
              .read(connectedDevicesProvider.notifier)
              .getServices(device, shouldConnect: false),
        );
      }
      if (!_stopped &&
          !AppLifecycleManager.isInBackground &&
          canUseBluetooth(ref.read(appInitializerProvider).valueOrNull) &&
          (prefs.getBool('autoConnect') ?? true) &&
          prefs.getBool('user_disconnected_$id') != true &&
          prefs.getBool('forgotten_$id') != true) {
        unawaited(ref.read(connectedDevicesProvider.notifier).connect(device));
      }
    }
    state = BLEDevices(
      available: _discovered.values.where((d) => !ids.contains(d.id)).toList(),
      paired: paired,
    );
  }

  void _start() {
    if (_stopped ||
        _disposed ||
        _scan != null ||
        !canUseBluetooth(ref.read(appInitializerProvider).valueOrNull) ||
        ref.read(bleStatusNotifierProvider) != BleStatus.ready) {
      return;
    }
    final generation = ++_generation;
    void restart() {
      if (_stopped || _disposed || generation != _generation) return;
      unawaited(_scan?.cancel());
      _scan = null;
      _cycle?.cancel();
      _restart?.cancel();
      _restart = Timer(const Duration(seconds: 5), _start);
    }

    _discovered.clear();
    _scan = ref
        .read(bleClientProvider)
        .scanForDevices(
          withServices: [Uuid.parse(configs.setThresholdUUIDS.service)],
          scanMode: ScanMode.balanced,
        )
        .listen(
          (device) {
            if (_stopped || generation != _generation) return;
            _discovered[device.id] = device;
            updateDeviceStreams();
          },
          onError: (Object _) => restart(),
          onDone: restart,
        );
    _cycle = Timer(const Duration(seconds: 35), restart);
    updateDeviceStreams();
  }

  void stopScan() {
    _stopped = true;
    ++_generation;
    _cycle?.cancel();
    _restart?.cancel();
    unawaited(_scan?.cancel());
    _scan = null;
  }

  void refreshScan() {
    stopScan();
    if (_disposed || AppLifecycleManager.isInBackground) return;
    _stopped = false;
    updateDeviceStreams();
    _start();
  }

  Future<void> addPairedDevice(DiscoveredDevice device) async {
    await ref.read(connectedDevicesProvider.notifier).connect(device);
    updateDeviceStreams();
  }
}

class BLEDevices {
  final List<DiscoveredDevice> available;
  final List<DiscoveredDevice> paired;
  BLEDevices({required this.available, required this.paired});
}
