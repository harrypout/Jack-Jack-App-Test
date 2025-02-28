import 'package:ble/screens/notifications/notification_screen.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:ble/widgets/ble_background.dart';
import 'package:ble/widgets/ble_gauge.dart';
import 'package:ble/widgets/ble_home_screen_device.dart';
import 'package:ble/widgets/ble_indicator_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const String id = 'home_screen';
  const HomeScreen({super.key});

  @override
  ConsumerState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
              spacing: 12,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome",
                          style: const TextStyle(
                            color: Color(0xFF121521),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text("Good Morning!"),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, NotificationScreen.id);
                      },
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
                        minimumSize: WidgetStatePropertyAll(Size.zero),
                      ),
                      child: Icon(Icons.notifications),
                    ),
                  ],
                ),
                BLEGauge(selectedDevice: "Sound Sense 1",),
                SizedBox(
                  height: 80,
                  child: Row(
                    spacing: 16,
                    children: [
                      IndicatorBox(
                        title: "Battery",
                        subtitle: "100%",
                        asset: "battery",
                      ),
                      IndicatorBox(
                        title: "Status",
                        subtitle: "Connected",
                        asset: "status",
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Other Devices"),
                    TextButton(onPressed: () {}, child: Text("View All")),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      spacing: 12,
                      children: [
                        HomeScreenDevice(
                          deviceName: "Sound Sense 1",
                          battery: "100%",
                          threshold: 90,
                          isSelected: true,
                          isConnected: true,
                        ),
                        HomeScreenDevice(
                          deviceName: "Sound Sense 2",
                          battery: "99%",
                          threshold: 80,
                          isSelected: false,
                          isConnected: true,
                        ),
                        HomeScreenDevice(
                          deviceName: "Sound Sense 3",
                          battery: "98%",
                          threshold: 70,
                          isSelected: false,
                          isConnected: false,
                        ),
                        SizedBox(height: 45),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
