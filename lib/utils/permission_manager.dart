import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionManager {
  static int? _cachedAndroidVersion;

  static Future<bool> check({bool request = true}) async {
    if (Platform.isAndroid) {
      final version = await _getAndroidVersion();
      final requiredPermissions =
          version >= 31
              ? [Permission.bluetoothScan, Permission.bluetoothConnect]
              : [Permission.bluetooth, Permission.location];

      // Fast path: check if all permissions are already granted
      bool allAlreadyGranted = true;
      for (final permission in requiredPermissions) {
        if (!await permission.isGranted) {
          allAlreadyGranted = false;
          break;
        }
      }

      if (allAlreadyGranted) {
        debugPrint('BLE permissions already granted, skipping request');
        return true;
      }

      if (!request) return false;
      // Slow path: request permissions (shows OS dialog)
      final statuses = await requiredPermissions.request();
      final allGranted =
          !statuses.values.any((status) => status != PermissionStatus.granted);
      if (!allGranted) {
        debugPrint('Some permissions were denied: $statuses');
      }
      return allGranted;
    } else if (Platform.isIOS) {
      if (await Permission.bluetooth.isGranted) {
        debugPrint('Bluetooth permission already granted on iOS');
        return true;
      }

      if (!request) return false;
      final statuses = await [Permission.bluetooth].request();
      final allGranted =
          !statuses.values.any((status) => status != PermissionStatus.granted);
      if (!allGranted) {
        debugPrint('Bluetooth permission was denied: $statuses');
      }
      return allGranted;
    }

    return false;
  }

  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    if (_cachedAndroidVersion != null) return _cachedAndroidVersion!;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    _cachedAndroidVersion = androidInfo.version.sdkInt;
    return _cachedAndroidVersion!;
  }
}
