import 'dart:async';
import 'dart:math';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

enum ConnectionPhase { connecting, monitoring, retrying, stopped }

/// Owns exactly one native connection. Reconnection always initializes a new
/// GATT session. Every asynchronous completion is checked against its session.
class DeviceConnection {
  final FlutterReactiveBle ble;
  final String id;
  final Future<void> Function(bool Function() isCurrent) initialize;
  final Future<void> Function() release;
  final void Function(ConnectionPhase phase, Object? error) onPhase;
  final Duration timeout;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<BleStatus>? _status;
  Timer? _retry;
  Timer? _deadline;
  int _generation = 0;
  int _failures = 0;
  bool _stopped = false;
  bool _starting = false;
  final Completer<bool> _first = Completer<bool>();
  Future<void> _cleanup = Future.value();

  DeviceConnection({
    required this.ble,
    required this.id,
    required this.initialize,
    required this.release,
    required this.onPhase,
    this.timeout = const Duration(seconds: 20),
  });

  Future<bool> start() {
    _status ??= ble.statusStream.listen(
      (status) {
        if (_stopped) return;
        if (status == BleStatus.ready) {
          if (_connection == null && !_starting) {
            _retry?.cancel();
            _start();
          }
        } else {
          recover(StateError('Bluetooth is ${status.name}'));
        }
      },
      onError: (Object error) {
        recover(error);
      },
    );
    _start();
    return _first.future;
  }

  void _start() {
    if (_stopped || _starting || _connection != null) return;
    if (ble.status != BleStatus.ready) {
      onPhase(ConnectionPhase.retrying, StateError('Bluetooth is not ready'));
      if (!_first.isCompleted) _first.complete(false);
      return;
    }
    _starting = true;
    final generation = ++_generation;
    onPhase(ConnectionPhase.connecting, null);
    _deadline?.cancel();
    _deadline = Timer(timeout, () {
      if (generation == _generation) {
        recover(TimeoutException('Connection setup timed out'));
      }
    });
    _cleanup
        .then((_) {
          if (_stopped || generation != _generation) return;
          _starting = false;
          var initializing = false;
          _connection = ble
              .connectToDevice(id: id, connectionTimeout: timeout)
              .listen(
                (update) async {
                  if (_stopped || generation != _generation) return;
                  if (update.connectionState ==
                          DeviceConnectionState.connected &&
                      !initializing) {
                    initializing = true;
                    try {
                      await initialize(
                        () => !_stopped && generation == _generation,
                      ).timeout(timeout);
                      if (_stopped || generation != _generation) return;
                      _deadline?.cancel();
                      _failures = 0;
                      onPhase(ConnectionPhase.monitoring, null);
                      if (!_first.isCompleted) _first.complete(true);
                    } catch (error) {
                      if (generation == _generation) recover(error);
                    }
                  } else if (update.connectionState ==
                      DeviceConnectionState.disconnected) {
                    recover(StateError('Device disconnected'));
                  }
                },
                onError: (Object error) {
                  if (generation == _generation) recover(error);
                },
                onDone: () {
                  if (generation == _generation) {
                    recover(StateError('Connection stream ended'));
                  }
                },
              );
        })
        .catchError((Object error) {
          _starting = false;
          recover(error);
        });
  }

  void recover(Object error) {
    if (_stopped) return;
    ++_generation;
    _starting = false;
    _retry?.cancel();
    _deadline?.cancel();
    final old = _connection;
    _connection = null;
    _cleanup = _cleanup.then((_) async {
      await old?.cancel();
      await release();
    });
    onPhase(ConnectionPhase.retrying, error);
    if (!_first.isCompleted) _first.complete(false);
    final seconds = min(30, 1 << min(++_failures, 5));
    _retry = Timer(Duration(seconds: seconds), _start);
  }

  Future<void> stop() async {
    _stopped = true;
    ++_generation;
    _retry?.cancel();
    _deadline?.cancel();
    await _status?.cancel();
    await _connection?.cancel();
    _connection = null;
    await _cleanup;
    await release();
    if (!_first.isCompleted) _first.complete(false);
    onPhase(ConnectionPhase.stopped, null);
  }
}
