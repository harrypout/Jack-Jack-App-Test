import 'package:jackjack/models/ble_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BLEDevice {
  DiscoveredDevice device;
  BLEService getThreshold;
  BLEService setThreshold;
  BLEService getBattery;
  BLEService thresholdAlert;
  BLEService getSoundLevel;
  BLEService setSoundLevel;
  BLEService getSound;
  BLEService setSound;

  BLEDevice({
    required this.device,
    required this.getThreshold,
    required this.setThreshold,
    required this.getBattery,
    required this.thresholdAlert,
    required this.getSoundLevel,
    required this.setSoundLevel,
    required this.getSound,
    required this.setSound,
  });
}