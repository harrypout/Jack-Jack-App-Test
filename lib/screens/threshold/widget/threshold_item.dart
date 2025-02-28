import 'package:ble/utils/color_manager.dart';
import 'package:ble/widgets/ble_pill.dart';
import 'package:ble/widgets/ble_toggle.dart';
import 'package:flutter/material.dart';

class ThresholdItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final int threshold;
  const ThresholdItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.threshold,
  });

  @override
  State<ThresholdItem> createState() => _ThresholdItemState();
}

class _ThresholdItemState extends State<ThresholdItem> {
  double threshold = 0;
  bool sound = false;
  bool vibration = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      threshold = widget.threshold.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border.all(width: 1, color: ColorManager.containerBorder),
      ),
      child: ExpansionTile(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: ColorManager.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          spacing: 6,
          children: [
            Text(
              widget.subtitle,
              style: const TextStyle(
                color: ColorManager.tertiaryText,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            BLEPill(),
            Text(
              "${threshold.toInt()} DB",
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: ColorManager.tertiaryText,
              ),
            ),
          ],
        ),
        backgroundColor: ColorManager.transparent,
        collapsedBackgroundColor: ColorManager.transparent,
        shape: RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: null,
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
                "${threshold.toInt()} DB",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: ColorManager.tertiaryText,
                ),
              ),
              Slider(
                value: threshold,
                max: 120,
                min: 0,
                activeColor: ColorManager.accent,
                onChanged: (value) {
                  setState(() {
                    threshold = value;
                  });
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
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
