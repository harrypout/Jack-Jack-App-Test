import 'package:jackjack/providers/notifications_provider.dart';
import 'package:jackjack/providers/selected_device_provider.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/screens/home/widgets/selected_device_widget.dart';
import 'package:jackjack/screens/notifications/notification_screen.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_background.dart';
import 'package:jackjack/widgets/ble_home_screen_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jackjack/services/app_initializer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const String id = 'home_screen';
  const HomeScreen({super.key});

  @override
  ConsumerState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final connectedDevices = ref.watch(connectedDevicesProvider);
    final selectedDevice = ref.watch(selectedDeviceProvider);
    if (connectedDevices.isNotEmpty && selectedDevice == null) {
      Future.microtask(
        () => ref
            .read(selectedDeviceProvider.notifier)
            .setSelectedDevice(connectedDevices.keys.first),
      );
    }
    final bleStatus = ref.watch(bleStatusNotifierProvider);
    final btOff = bleStatus != BleStatus.ready;

    return Scaffold(
      body: BLEBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ThemeManager.horizontalPadding,
            ),
            child: Column(
              spacing: 12,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Jack Jack",
                          style: const TextStyle(
                            color: ColorManager.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Text("Good Morning!"),
                      ],
                    ),
                    Badge(
                      isLabelVisible:
                          ref.watch(notificationsProvider).isNotEmpty
                              ? true
                              : false,
                      label:
                          ref.watch(notificationsProvider).isNotEmpty
                              ? Container()
                              : null,
                      offset: Offset(-4, 4),
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, NotificationScreen.id);
                        },
                        style: ButtonStyle(
                          padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
                          minimumSize: WidgetStatePropertyAll(Size.zero),
                        ),
                        child: Icon(Icons.notifications),
                      ),
                    ),
                  ],
                ),
                if (btOff)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorManager.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ColorManager.containerBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          color: ColorManager.tertiaryText,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bluetooth is turned off. Turn on Bluetooth to connect to devices.',
                            style: TextStyle(
                              fontSize: 13,
                              color: ColorManager.tertiaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SelectedDeviceHomeWidget(
                  device: connectedDevices[selectedDevice],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Devices"),
                    // TextButton(onPressed: () {}, child: Text("View All")),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: connectedDevices.length,
                    itemBuilder: (context, index) {
                      final id = connectedDevices.keys.elementAt(index);
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: id == connectedDevices.keys.last ? 45 : 0,
                        ),
                        child: HomeScreenDevice(
                          device: connectedDevices[id]!,
                          isSelected: selectedDevice == id,
                        ),
                      );
                    },
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
