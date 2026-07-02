import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceNameManager {
  static const String _deviceNamesKey = 'device_names';
  static DeviceNameManager? _instance;
  late SharedPreferences _prefs;

  DeviceNameManager._();

  static DeviceNameManager get instance {
    _instance ??= DeviceNameManager._();
    return _instance!;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Map<String, String> getDeviceNames() {
    final namesJson = _prefs.getString(_deviceNamesKey);
    if (namesJson == null) return {};

    try {
      final Map<String, dynamic> decoded = jsonDecode(namesJson);
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return {};
    }
  }

  Future<void> setDeviceName(String deviceId, String name) async {
    final currentNames = getDeviceNames();
    currentNames[deviceId] = name;

    await _prefs.setString(_deviceNamesKey, jsonEncode(currentNames));
  }

  Future<void> removeDeviceName(String deviceId) async {
    final currentNames = getDeviceNames();
    currentNames.remove(deviceId);

    await _prefs.setString(_deviceNamesKey, jsonEncode(currentNames));
  }

  String? getDeviceName(String deviceId) {
    return getDeviceNames()[deviceId];
  }

  String getDisplayName(String deviceId, String fallbackName) {
    return getDeviceName(deviceId) ?? fallbackName;
  }
}

// Provider for device name manager
final deviceNameManagerProvider = Provider<DeviceNameManager>((ref) {
  return DeviceNameManager.instance;
});

// Provider that watches device names and triggers rebuilds when they change
final deviceNamesProvider =
    StateNotifierProvider<DeviceNamesNotifier, Map<String, String>>((ref) {
      return DeviceNamesNotifier();
    });

class DeviceNamesNotifier extends StateNotifier<Map<String, String>> {
  DeviceNamesNotifier() : super({}) {
    _loadDeviceNames();
  }

  Future<void> _loadDeviceNames() async {
    final deviceNameManager = DeviceNameManager.instance;
    await deviceNameManager.initialize();
    state = deviceNameManager.getDeviceNames();
  }

  Future<void> setDeviceName(String deviceId, String name) async {
    final deviceNameManager = DeviceNameManager.instance;
    await deviceNameManager.setDeviceName(deviceId, name);
    state = deviceNameManager.getDeviceNames();
  }

  Future<void> removeDeviceName(String deviceId) async {
    final deviceNameManager = DeviceNameManager.instance;
    await deviceNameManager.removeDeviceName(deviceId);
    state = deviceNameManager.getDeviceNames();
  }

  String? getDeviceName(String deviceId) {
    return state[deviceId];
  }

  String getDisplayName(String deviceId, String fallbackName) {
    return state[deviceId] ?? fallbackName;
  }
}
