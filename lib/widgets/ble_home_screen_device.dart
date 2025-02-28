import 'package:ble/utils/color_manager.dart';
import 'package:ble/widgets/ble_pill.dart';
import 'package:ble/widgets/ble_toggle.dart';
import 'package:flutter/material.dart';

class HomeScreenDevice extends StatefulWidget {
  final String deviceName;
  final String battery;
  final int threshold;
  final bool isSelected;
  final bool isConnected;
  const HomeScreenDevice({
    super.key,
    required this.deviceName,
    required this.battery,
    required this.threshold,
    required this.isSelected,
    required this.isConnected,
  });

  @override
  State<HomeScreenDevice> createState() => _HomeScreenDeviceState();
}

class _HomeScreenDeviceState extends State<HomeScreenDevice> {
  bool on = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      on = widget.isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      // height: 74,
      padding: const EdgeInsets.all(14),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color:
            widget.isSelected
                ? ColorManager.selectedContainerBackground
                : ColorManager.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color:
                widget.isSelected
                    ? ColorManager.selectedContainerBorder
                    : ColorManager.containerBorder,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 12,
                children: [
                  Text(
                    widget.deviceName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: ColorManager.primaryText,
                    ),
                  ),
                  if (widget.isSelected)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 4,
                      children: [
                        BLEPill(color: Colors.green),
                        Text(
                          "Current",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: ColorManager.secondaryText,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 4,
                children: [
                  Text(
                    widget.battery,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: ColorManager.tertiaryText,
                    ),
                  ),
                  BLEPill(),
                  Text(
                    on ? "Connected" : "Disconnected",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: ColorManager.tertiaryText,
                    ),
                  ),
                  BLEPill(),
                  Text(
                    "${widget.threshold} DB",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: ColorManager.tertiaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          BLEToggle(
            value: on,
            onChanged: (value) {
              setState(() {
                on = value;
              });
            },
          ),
        ],
      ),
    );
  }
}