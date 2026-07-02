import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/providers/device_threshold_provider.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/widgets/ble_pill.dart';
import 'package:jackjack/widgets/ble_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main.dart';

class ThresholdItem extends ConsumerStatefulWidget {
  final BLEDevice device;
  const ThresholdItem({super.key, required this.device});

  @override
  ConsumerState createState() => _ThresholdItemState();
}

class _ThresholdItemState extends ConsumerState<ThresholdItem> {
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
    return threshold == null ||
            (threshold != null && (threshold < 30 || threshold > 120))
        ? Container()
        : ExpansionTile(
          title: Text(
            widget.device.device.name,
            style: const TextStyle(
              color: ColorManager.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Row(
            spacing: 6,
            children: [
              if (sound || vibration)
                Text(
                  "${sound ? "Sound" : ""}${sound && vibration ? " & " : ""}${vibration ? "Vibration" : ""}${sound || vibration ? " Alert" : ""}",
                  style: const TextStyle(
                    color: ColorManager.tertiaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              if (sound || vibration) BLEPill(),
              Text(
                "${threshold?.toInt()} DB",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: ColorManager.tertiaryText,
                ),
              ),
            ],
          ),
          backgroundColor: ColorManager.white,
          collapsedBackgroundColor: ColorManager.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: ColorManager.containerBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          collapsedShape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: ColorManager.containerBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          childrenPadding: EdgeInsets.all(16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          children: [
            Text(
              "Set Sound Threshold ",
              style: const TextStyle(
                color: ColorManager.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${threshold?.toInt()} DB",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: ColorManager.tertiaryText,
                  ),
                ),
                Slider(
                  value: threshold!.toDouble(),
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
                  onChangeEnd: (value) {
                    ref
                        .read(
                          deviceThresholdProvider(
                            widget.device.device.id,
                          ).notifier,
                        )
                        .saveToDevice(widget.device.device.id, value.toInt());
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Sound Alert",
                      style: const TextStyle(
                        color: ColorManager.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    BLEToggle(
                      value: sound,
                      onChanged: (value) {
                        setState(() {
                          sound = value;
                        });
                        prefs.setBool("${widget.device.device.id}s", value);
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Vibration Alert",
                      style: const TextStyle(
                        color: ColorManager.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    BLEToggle(
                      value: vibration,
                      onChanged: (value) {
                        setState(() {
                          vibration = value;
                        });
                        prefs.setBool("${widget.device.device.id}v", value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
  }
}
