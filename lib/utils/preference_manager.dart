import 'package:ble/main.dart';

  //TODO: replace SharedPreferences with DeviceBasedStorage
class PreferencesManager {
  static Future<void> saveDeviceThreshold(String deviceId, int threshold) async {
    await prefs.setInt(deviceId, threshold);
  }

  static int getDeviceThreshold(String deviceId, {int defaultValue = 80}) {
    return prefs.getInt(deviceId) ?? defaultValue;
  }

  static Future<void> clearAllThresholds() async {
    prefs.clear();
  }
}