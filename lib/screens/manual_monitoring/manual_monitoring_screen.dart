import 'package:jackjack/providers/selected_device_provider.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/screens/manual_monitoring/providers/manual_monitoring_provider.dart';
import 'package:jackjack/screens/pairing/pods/connected_device_tracker.dart';
import 'package:jackjack/screens/pairing/widgets/scanner.dart';
import 'package:jackjack/widgets/ble_filled_button.dart';
import 'package:jackjack/widgets/ble_gauge.dart';
import 'package:jackjack/widgets/ble_indicator_box.dart';
import 'package:jackjack/widgets/ble_outlined_button.dart';
import 'package:jackjack/widgets/ble_pill.dart';
import 'package:jackjack/widgets/ble_toggle.dart';
import 'package:flutter/material.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class ManualMonitoringScreen extends ConsumerStatefulWidget {
  static const String id = 'manual_monitoring_screen';
  const ManualMonitoringScreen({super.key});

  @override
  ConsumerState createState() => _ManualMonitoringScreenState();
}

class _ManualMonitoringScreenState
    extends ConsumerState<ManualMonitoringScreen> {
  @override
  Widget build(BuildContext context) {
    final connectedDevices = ref.watch(connectedDevicesProvider);
    final selectedDevice = ref.watch(selectedDeviceProvider);
    final manualMonitoringPod = ref.watch(manualMonitoringProvider);
    return Scaffold(
      body: BLEBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ThemeManager.horizontalPadding,
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        manualMonitoringPod.isStreaming
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                    children: [
                      if (manualMonitoringPod.isStreaming)
                        Column(
                          children: [
                            BLEGauge(
                              selectedDevice:
                                  connectedDevices[selectedDevice]
                                      ?.device
                                      .name ??
                                  "No Device Selected",
                              valueStream:
                                  connectedDevices[selectedDevice]
                                      ?.getSoundLevel
                                      .data,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 6,
                                children: [
                                  BLEPill(color: Colors.red),
                                  Text(
                                    "Streaming ${_formatDuration(manualMonitoringPod.streamingDuration)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: ColorManager.quaternaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 80,
                              child: Row(
                                spacing: 16,
                                children: [
                                  IndicatorBox(
                                    title: "Battery",
                                    subtitle:
                                        "${connectedDevices[selectedDevice]?.getBattery.data ?? "0"} %",
                                    asset: "battery",
                                  ),
                                  IndicatorBox(
                                    title: "Status",
                                    subtitle:
                                        ref
                                                .read(
                                                  connectedDevicesTrackerProvider
                                                      .notifier,
                                                )
                                                .isDeviceConnected(
                                                  connectedDevices[selectedDevice]
                                                      ?.device
                                                      .id,
                                                )
                                            ? "Connected"
                                            : "Disconnected",
                                    asset: "status",
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              width: double.maxFinite,
                              // height: 74,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              clipBehavior: Clip.antiAlias,
                              decoration: ShapeDecoration(
                                color: ColorManager.white,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1,
                                    color: ColorManager.containerBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    spacing: 12,
                                    children: [
                                      SvgPicture.asset("assets/svgs/sound.svg"),
                                      Text(
                                        "Background Audio",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: ColorManager.primaryText,
                                        ),
                                      ),
                                    ],
                                  ),

                                  BLEToggle(value: true, onChanged: (value) {}),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Scanner(asset: "microphone", animate: false),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: _buildMainText(ref),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                _buildActionButton(
                  ref
                          .read(connectedDevicesTrackerProvider.notifier)
                          .isDeviceConnected(
                            connectedDevices[selectedDevice]?.device.id,
                          ),
                  ref,
                ),
                SizedBox(height: 45),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "Manual Monitoring Mode",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: ColorManager.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildMainText(WidgetRef ref) {
    final manualMonitoringPod = ref.watch(manualMonitoringProvider);
    if (manualMonitoringPod.showCountdown) {
      return Column(
        children: [
          Text(
            'Streaming starting in...',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: ColorManager.primaryText,
            ),
          ),
          const SizedBox(height: 10),

          Text(
            '${manualMonitoringPod.remainingTime}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: ColorManager.accent,
            ),
          ),
        ],
      );
    }

    return Text(
      manualMonitoringPod.isStreaming
          ? 'Streaming in progress'
          : 'Stream real-time audio from your device and monitor sound levels with precision',
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: ColorManager.primaryText,
      ),
    );
  }

  Widget _buildActionButton(bool isConnected, WidgetRef ref) {
    final manualMonitoringPod = ref.watch(manualMonitoringProvider);
    if (manualMonitoringPod.showCountdown) {
      return Column(
        children: [
          BLEOutlinedButton(
            data: "Skip Countdown",
            onPressed:
                ref.read(manualMonitoringProvider.notifier).startStreaming,
            textColor: ColorManager.primaryText,
            borderColor: ColorManager.containerBorder,
          ),
          const SizedBox(height: 10),
        ],
      );
    }

    return BLEFilledButton(
      data:
          manualMonitoringPod.isStreaming
              ? "Stop Streaming"
              : "Start Streaming",
      onPressed: () {
        manualMonitoringPod.isStreaming
            ? ref.read(manualMonitoringProvider.notifier).stopStreaming()
            : ref
                .read(manualMonitoringProvider.notifier)
                .startCountdown(isConnected);
      },
      icon: SvgPicture.asset(
        "assets/svgs/${manualMonitoringPod.isStreaming ? "stop" : "play"}.svg",
      ),
    );
  }

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;

    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    return "$hoursStr:$minutesStr:$secondsStr";
  }
}
