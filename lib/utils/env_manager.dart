import 'package:jackjack/models/ble_uuids.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

EnvManager configs = EnvManager.getInstanceSync();

class EnvManager {
  static EnvManager? _instance;

  static Future<EnvManager> getInstance() async {
    if (_instance == null) {
      await dotenv.load();
      _instance = EnvManager._internal();
    }
    return _instance!;
  }

  String getEnv(String name, {String fallback = ""}) {
    return dotenv.get(name, fallback: fallback);
  }

  BLEUUIDS getEnvBLEUUIDS(String name) => BLEUUIDS(
    name: name,
    service: getEnv("${name}_SERVICE"),
    characteristic: getEnv("${name}_CHARACTERISTIC"),
  );

  static EnvManager getInstanceSync() {
    if (_instance == null) throw Exception("ERROR: Configs not initialized");
    return _instance!;
  }

  EnvManager._internal();

  BLEUUIDS get getThresholdUUIDS => getEnvBLEUUIDS("GET_THRESHOLD");
  BLEUUIDS get setThresholdUUIDS => getEnvBLEUUIDS("SET_THRESHOLD");
  BLEUUIDS get getBatteryUUIDS => getEnvBLEUUIDS("GET_BATTERY");
  BLEUUIDS get thresholdAlertUUIDS => getEnvBLEUUIDS("THRESHOLD_ALERT");
  BLEUUIDS get getSoundLevelUUIDS => getEnvBLEUUIDS("GET_SOUND_LEVEL");
  BLEUUIDS get setSoundLevelUUIDS => getEnvBLEUUIDS("SET_SOUND_LEVEL");
  BLEUUIDS get getSoundUUIDS => getEnvBLEUUIDS("GET_SOUND");
  BLEUUIDS get setSoundUUIDS => getEnvBLEUUIDS("SET_SOUND");

  List<BLEUUIDS> get uuids => [
    getThresholdUUIDS,
    setThresholdUUIDS,
    getBatteryUUIDS,
    thresholdAlertUUIDS,
    getSoundLevelUUIDS,
    setSoundLevelUUIDS,
    getSoundUUIDS,
    setSoundUUIDS,
  ];
}
