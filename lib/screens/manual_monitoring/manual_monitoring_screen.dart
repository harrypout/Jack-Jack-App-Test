import 'package:ble/screens/pairing/widgets/scanner.dart';
import 'package:ble/widgets/ble_filled_button.dart';
import 'package:ble/widgets/ble_gauge.dart';
import 'package:ble/widgets/ble_indicator_box.dart';
import 'package:ble/widgets/ble_outlined_button.dart';
import 'package:ble/widgets/ble_pill.dart';
import 'package:ble/widgets/ble_toggle.dart';
import 'package:flutter/material.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:ble/widgets/ble_background.dart';
import 'dart:async';
import 'package:flutter_svg/svg.dart';

class ManualMonitoringScreen extends StatefulWidget {
  static const String id = 'manual_monitoring_screen';
  const ManualMonitoringScreen({super.key});

  @override
  State<ManualMonitoringScreen> createState() => _ManualMonitoringScreenState();
}

class _ManualMonitoringScreenState extends State<ManualMonitoringScreen> {
  final int _countdownDuration = 5;
  int _remainingTime = 5;
  Timer? _countdownTimer;
  Timer? _streamingTimer;
  bool _isStreaming = false;
  bool _showCountdown = false;
  int _streamingDuration = 0; // Track streaming duration in seconds

  void _startCountdown() {
    setState(() {
      _showCountdown = true;
      _remainingTime = _countdownDuration;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        _startStreaming();
      }
    });
  }

  void _startStreaming() {
    _countdownTimer?.cancel();
    setState(() {
      _showCountdown = false;
      _isStreaming = true;
      _streamingDuration = 0;
    });

    // Start the streaming timer
    _streamingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _streamingDuration++;
      });
    });
  }

  void _stopStreaming() {
    setState(() {
      _isStreaming = false;
      _showCountdown = false;
      _streamingDuration = 0;
    });

    _streamingTimer?.cancel(); // Stop the timer
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _streamingTimer?.cancel();
    super.dispose();
  }

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
                _buildHeader(),
                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        _isStreaming
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                    children: [
                      if (_isStreaming)
                        Column(
                          children: [
                            const BLEGauge(selectedDevice: "Sound Sense 1",),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 6,
                                children: [
                                  BLEPill(
                                    color: Colors.red,
                                  ),
                                  Text(
                                    "Streaming ${_formatDuration(_streamingDuration)}",
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
                            Scanner(asset: "microphone"),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: _buildMainText(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                _buildActionButton(),
                SizedBox(height: 45,),
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

  Widget _buildMainText() {
    if (_showCountdown) {
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
            '$_remainingTime',
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
      _isStreaming
          ? 'Streaming in progress'
          : 'Stream real-time audio from your device and monitor sound levels with precision',
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: ColorManager.primaryText,
      ),
    );
  }

  Widget _buildActionButton() {
    if (_showCountdown) {
      return Column(
        children: [
          BLEOutlinedButton(
            data: "Skip Countdown",
            onPressed: _startStreaming,
            textColor: ColorManager.primaryText,
            borderColor: ColorManager.containerBorder,
          ),
          const SizedBox(height: 10),
        ],
      );
    }

    return BLEFilledButton(
      data: _isStreaming ? "Stop Streaming" : "Start Streaming",
      onPressed: _isStreaming ? _stopStreaming : _startCountdown,
      icon: SvgPicture.asset(
        "assets/svgs/${_isStreaming ? "stop" : "play"}.svg",
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

    return "$hoursStr:$minutesStr:$secondsStr"; // HH:MM:SS format
  }
}
