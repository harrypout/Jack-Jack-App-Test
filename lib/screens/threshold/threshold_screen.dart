import 'package:ble/screens/threshold/widget/threshold_item.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:ble/widgets/ble_app_bar.dart';
import 'package:ble/widgets/ble_background.dart';
import 'package:flutter/material.dart';

class ThresholdScreen extends StatelessWidget {
  static const String id = 'threshold_screen';
  const ThresholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BLEBackground(
        child: SafeArea(
          child: Column(
            children: [
              BLEAppBar(title: "Threshold Settings"),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ThemeManager.horizontalPadding),
                child: ThresholdItem(
                  title: "Sound Sense 1",
                  subtitle: "Sound Alert",
                  threshold: 70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
