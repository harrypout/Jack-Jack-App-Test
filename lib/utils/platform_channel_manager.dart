import 'package:flutter/services.dart';
import 'dart:io';

class PlatformChannelManager {
  static const platform = MethodChannel('com.jackjack/background');

  /// Request battery optimization exemption on Android
  /// Opens system settings where user can exempt the app
  static Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return false;

    try {
      final result =
          await platform.invokeMethod('requestBatteryOptimizationExemption');
      return result as bool;
    } catch (e) {
      print('Error requesting battery optimization exemption: $e');
      return false;
    }
  }

  /// Check if app is ignoring battery optimizations (Android)
  /// Returns true if already exempted or if not Android
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;

    try {
      final result =
          await platform.invokeMethod('isIgnoringBatteryOptimizations');
      return result as bool;
    } catch (e) {
      print('Error checking battery optimization status: $e');
      return false;
    }
  }

  /// Move app to background instead of finishing the activity (Android).
  /// Makes the back button behave like the home button so the background
  /// service stays alive.
  static Future<void> moveToBackground() async {
    if (!Platform.isAndroid) return;
    try {
      await platform.invokeMethod('moveToBackground');
    } catch (e) {
      print('Error moving to background: $e');
    }
  }

  /// Setup method call handler for iOS background tasks
  /// This listens for callbacks from native iOS code
  static void setupBackgroundTaskHandler() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'executeBatteryPoll':
          // iOS background task triggered - battery poll
          print('📱 iOS background task: battery poll');
          // Notify background service if needed
          break;
        case 'executeBLEMonitor':
          // iOS background task triggered - BLE monitor
          print('📱 iOS background task: BLE monitor');
          // Notify background service if needed
          break;
        default:
          throw PlatformException(
            code: 'Unimplemented',
            details: 'Method ${call.method} not implemented',
          );
      }
    });
  }
}
