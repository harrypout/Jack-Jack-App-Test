import 'package:ble/providers/notifications_provider.dart';
import 'package:ble/providers/selected_device_provider.dart';
import 'package:ble/providers/connected_devices_provider.dart';
import 'package:ble/screens/home/widgets/selected_device_widget.dart';
import 'package:ble/screens/notifications/notification_screen.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:ble/widgets/ble_background.dart';
import 'package:ble/widgets/ble_home_screen_device.dart';
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
    final connectedDevices = ref.watch(connectedDevicesProvider);
    final selectedDevice = ref.watch(selectedDeviceProvider);
    if (connectedDevices.isNotEmpty && selectedDevice == null) {
      Future.microtask(
        () => ref
            .read(selectedDeviceProvider.notifier)
            .setSelectedDevice(connectedDevices.keys.first),
      );
    }
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
                Expanded(
                  flex: 7,
                  child: SelectedDeviceHomeWidget(
                    device: connectedDevices[selectedDevice],
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
                  flex: 8,
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
