import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Controls the Android foreground service that keeps the app process (and
/// therefore the active BLE connections) alive while devices are connected.
///
/// No-op on non-Android platforms. iOS keeps BLE alive via the
/// `bluetooth-central` background mode declared in Info.plist.
class ForegroundServiceManager {
  static const MethodChannel _channel = MethodChannel(
    'com.jackjack/foreground_service',
  );

  static bool _running = false;

  /// Starts the foreground service if it isn't already running.
  static Future<void> start({
    String title = 'Monitoring devices',
    String text = 'Listening for sound alerts in the background',
  }) async {
    if (!Platform.isAndroid || _running) return;
    try {
      final started = await _channel.invokeMethod<bool>('start', {
        'title': title,
        'text': text,
      });
      _running = started ?? true;
    } catch (e) {
      debugPrint('Failed to start foreground service: $e');
    }
  }

  /// Stops the foreground service if it is running.
  static Future<void> stop() async {
    if (!Platform.isAndroid || !_running) return;
    try {
      await _channel.invokeMethod('stop');
      _running = false;
    } catch (e) {
      debugPrint('Failed to stop foreground service: $e');
    }
  }
}
