import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/providers/connected_status_provider.dart';
import 'package:jackjack/providers/device_threshold_provider.dart';
import 'package:jackjack/providers/loading_provider.dart';
import 'package:jackjack/providers/selected_device_provider.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/services/device_name_manager.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/status_colors.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_pebble.dart';
import 'package:jackjack/widgets/ble_pill.dart';
import 'package:jackjack/widgets/ble_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jackjack/widgets/ble_toggle_row.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../main.dart';
import 'package:jackjack/utils/toast_manager.dart';

class HomeScreenDevice extends ConsumerStatefulWidget {
  final BLEDevice device;
  final bool isSelected;

  const HomeScreenDevice({
    super.key,
    required this.device,
    this.isSelected = false,
  });

  @override
  ConsumerState createState() => _HomeScreenDeviceState();
}

class _HomeScreenDeviceState extends ConsumerState<HomeScreenDevice> {
  bool sound = true;
  bool vibration = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      sound = prefs.getBool("${widget.device.device.id}s") ?? true;
      vibration = prefs.getBool("${widget.device.device.id}v") ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final threshold = ref.watch(
      deviceThresholdProvider(widget.device.device.id),
    );
    final isLoading = ref.watch(loadingProvider(widget.device.device.id));
    final isConnected = ref.watch(
      connectedStatusProvider(widget.device.device.id),
    );
    final deviceNames = ref.watch(deviceNamesProvider);
    final displayName =
        deviceNames[widget.device.device.id] ?? widget.device.device.name;

    return Skeletonizer(
      enabled: isLoading,
      child: ExpansionTile(
        leading: BLEPebble(
          size: 34,
          tone: deviceTone(
            id: widget.device.device.id,
            isPrimary: widget.isSelected,
          ),
        ),
        title: Row(
          spacing: 8,
          children: [
            Flexible(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: ColorManager.slate,
                ),
              ),
            ),
            if (widget.isSelected)
              const BLEStatusPill(
                "Current",
                tone: PillTone.coral,
                leadingDot: true,
              ),
          ],
        ),
        subtitle: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4,
          spacing: 6,
          children: [
            Text(
              widget.device.getBattery.data == null
                  ? 'Battery unknown'
                  : '${widget.device.getBattery.data}%',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: batteryValueColor(
                  int.tryParse("${widget.device.getBattery.data}"),
                ),
              ),
            ),
            BLEPill(),
            Text(
              isConnected ? "Connected" : "Disconnected",
              style: ThemeManager.meta,
            ),
            BLEPill(),
            Text(
              threshold == null ? 'Threshold unknown' : '$threshold dB',
              style: ThemeManager.meta,
            ),
          ],
        ),
        // Default trailing chevron (styled slate) keeps the built-in
        // expand/collapse rotation affordance.
        iconColor: ColorManager.slate60,
        collapsedIconColor: ColorManager.slate60,
        backgroundColor: ColorManager.white,
        collapsedBackgroundColor: ColorManager.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: ColorManager.containerBorder),
          borderRadius: ThemeManager.brLg,
        ),
        collapsedShape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: ColorManager.containerBorder),
          borderRadius: ThemeManager.brLg,
        ),
        childrenPadding: EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        expandedAlignment: Alignment.topLeft,
        children: [
          BleToggleRow(
            "Connect",
            value:
                isConnected ||
                ref.watch(connectionDesiredProvider(widget.device.device.id)),
            onChanged: (value) async {
              debugPrint("onToggle: $value");
              final connected = await ref
                  .read(connectedDevicesProvider.notifier)
                  .connect(widget.device.device, shouldConnect: value);
              if (value && connected) {
                ref
                    .read(selectedDeviceProvider.notifier)
                    .setSelectedDevice(widget.device.device.id);
              }
              debugPrint("onToggle: $value");
            },
          ),
          if (isConnected)
            TextButton(
              onPressed:
                  widget.isSelected
                      ? null
                      : () => ref
                          .read(selectedDeviceProvider.notifier)
                          .setSelectedDevice(widget.device.device.id),
              child: Text(
                widget.isSelected ? 'Current device' : 'Show on meter',
              ),
            ),
          if (ref.watch(connectionErrorProvider(widget.device.device.id)) !=
              null)
            const Text('Connection interrupted. Reconnecting when available.'),
          BleToggleRow(
            "Alerts",
            value: sound || vibration,
            onChanged: (value) {
              setState(() {
                sound = value;
                vibration = value;
              });
              prefs.setBool("${widget.device.device.id}s", value);
              prefs.setBool("${widget.device.device.id}v", value);
            },
          ),
          // BleToggleRow(
          //   "Sound Alert",
          //   value: sound,
          //   onChanged: (value) {
          //     setState(() {
          //       sound = value;
          //        vibration = value;
          //     });
          //     prefs.setBool("${widget.device.device.id}s", value);
          //   },
          // ),
          // BleToggleRow(
          //   "Vibration Alert",
          //   value: vibration,
          //   onChanged: (value) {
          //     setState(() {
          //       vibration = value;
          //     });
          //     prefs.setBool("${widget.device.device.id}v", value);
          //   },
          // ),
          if (isConnected &&
              !(threshold == null || ((threshold < 30 || threshold > 120))))
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Set Sound Threshold ",
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: ColorManager.secondaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      "${threshold.toInt()} dB",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: ColorManager.tertiaryText,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: threshold.toDouble(),
                  max: 120,
                  min: 30,
                  activeColor: ColorManager.accent,
                  onChanged: (val) {
                    ref
                        .read(
                          deviceThresholdProvider(
                            widget.device.device.id,
                          ).notifier,
                        )
                        .change(val.toInt());
                  },
                  onChangeEnd: (value) async {
                    try {
                      await ref
                          .read(
                            deviceThresholdProvider(
                              widget.device.device.id,
                            ).notifier,
                          )
                          .saveToDevice(widget.device.device.id, value.toInt());
                      if (!mounted) return;
                      final confirmed = ref.read(
                        deviceThresholdProvider(widget.device.device.id),
                      );
                      if (confirmed != value.toInt()) {
                        ToastManager.show('Device confirmed $confirmed dB');
                      }
                    } catch (_) {
                      ToastManager.show(
                        'Threshold could not be saved. Last confirmed value restored.',
                      );
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
