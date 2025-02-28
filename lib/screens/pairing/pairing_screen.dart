import 'package:ble/screens/pairing/widgets/bluetooth_device.dart';
import 'package:ble/screens/pairing/widgets/scanner.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:ble/widgets/ble_background.dart';
import 'package:flutter/material.dart';

class PairingScreen extends StatelessWidget {
  static const String id = 'pairing_screen';

  const PairingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BLEBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ThemeManager.horizontalPadding,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Connect Device",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: ColorManager.primaryText,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Refresh",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: ColorManager.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                Scanner(asset: "bluetooth-search",),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Searching for Device...',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: ColorManager.primaryText,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Paired Devices",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: ColorManager.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                BluetoothDevice(name: "Sound Sense 1", isPaired: true),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Available Devices",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: ColorManager.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                BluetoothDevice(name: "Sound Sense 2", isPaired: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
