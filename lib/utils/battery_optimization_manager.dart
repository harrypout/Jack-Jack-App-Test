import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:jackjack/main.dart';

class BatteryOptimizationManager {
  static Future<void> check() async {
    bool? isBatteryOptimizationDisabled =
        await DisableBatteryOptimization.isBatteryOptimizationDisabled;
    if (!(isBatteryOptimizationDisabled ?? false)) {
      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
    }
    bool? isManBatteryOptimizationDisabled =
        await DisableBatteryOptimization
            .isManufacturerBatteryOptimizationDisabled;
    if (!(prefs.getBool('onboarding_status') ?? false) &&
        !(isManBatteryOptimizationDisabled ?? false)) {
      await DisableBatteryOptimization.showDisableManufacturerBatteryOptimizationSettings(
        "Your device has additional battery optimization",
        "Follow the steps and disable the optimizations to allow smooth functioning of this app",
      );
    }
  }
}
