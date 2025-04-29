import 'package:ble/providers/connected_devices_provider.dart';
import 'package:ble/screens/threshold/widget/threshold_item.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:ble/widgets/ble_app_bar.dart';
import 'package:ble/widgets/ble_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThresholdScreen extends ConsumerWidget {
  static const String id = 'threshold_screen';
  const ThresholdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectedDevices = ref.watch(connectedDevicesProvider);
    return Scaffold(
      body: BLEBackground(
        child: SafeArea(
          child: Column(
            children: [
              BLEAppBar(title: "Threshold Settings"),
              ...connectedDevices.keys.map(
                (id) => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ThemeManager.horizontalPadding,
                  ),
                  child: ThresholdItem(
                    device: connectedDevices[id]!,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
