import 'package:jackjack/models/ble_device.dart';
import 'package:jackjack/providers/connected_status_provider.dart';
import 'package:jackjack/providers/device_threshold_provider.dart';
import 'package:jackjack/providers/loading_provider.dart';
import 'package:jackjack/providers/selected_device_provider.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/widgets/ble_pill.dart';
import 'package:jackjack/widgets/ble_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  @override
  Widget build(BuildContext context) {
    final threshold = ref.watch(
      deviceThresholdProvider(widget.device.device.id),
    );
    final isLoading = ref.watch(loadingProvider(widget.device.device.id));
    final isConnected = ref.watch(
      connectedStatusProvider(widget.device.device.id),
    );

    return InkWell(
      onTap: () {
        ref
            .read(selectedDeviceProvider.notifier)
            .setSelectedDevice(widget.device.device.id);
      },
      child: Container(
        width: double.maxFinite,
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
        child: Skeletonizer(
          enabled: isLoading,
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
                        widget.device.device.name,
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
                        "${widget.device.getBattery.data}%",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: ColorManager.tertiaryText,
                        ),
                      ),
                      BLEPill(),
                      Text(
                        isConnected ? "Connected" : "Disconnected",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: ColorManager.tertiaryText,
                        ),
                      ),
                      BLEPill(),
                      Text(
                        "$threshold DB",
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
                value: isConnected,
                onChanged:
                    isLoading
                        ? (v) {}
                        : (value) async {
                          debugPrint("onToggle: $value");
                          await ref
                              .read(connectedDevicesProvider.notifier)
                              .connect(
                                widget.device.device,
                                shouldConnect: value,
                              );
                          // UI will auto-update via reactive provider - no manual toggle needed
                        },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
