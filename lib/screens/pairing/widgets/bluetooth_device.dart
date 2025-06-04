import 'package:jackjack/providers/loading_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/widgets/ble_bottom_sheet.dart';
import 'package:jackjack/screens/pairing/widgets/device_info_bottom_sheet.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BluetoothDeviceWidget extends ConsumerWidget {
  final DiscoveredDevice device;
  final bool isPaired;
  final bool loader;
  final Future<void> Function(DiscoveredDevice device)? onConnect;
  const BluetoothDeviceWidget({
    super.key,
    required this.device,
    required this.isPaired,
    this.onConnect,
    this.loader = false,
  });
  // bool isConnecting = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(loadingProvider(device.id));
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: ColorManager.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: ColorManager.containerBorder),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset("assets/svgs/device.svg"),
              const SizedBox(width: 12),
              Text(
                loader ? "Device Name" : device.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: ColorManager.primaryText,
                ),
              ),
            ],
          ),
          Skeletonizer(
            enabled: isLoading,
            child:
                isPaired
                    ? IconButton(
                      onPressed:
                          loader
                              ? null
                              : () {
                                BLEBottomSheet.openSheet(
                                  context,
                                  PairedInfoBottomSheet(device: device),
                                );
                              },
                      icon: SvgPicture.asset(
                        "assets/svgs/app-info.svg",
                        colorFilter: ColorFilter.mode(
                          Colors.blue,
                          BlendMode.srcIn,
                        ),
                      ),
                    )
                    : TextButton(
                      onPressed:
                          loader
                              ? null
                              : () async {
                                if (onConnect != null) {
                                  if (!isLoading) {
                                    ref
                                        .read(
                                          loadingProvider(
                                            device.id,
                                          ).notifier,
                                        )
                                        .toggle(true);
                                    await onConnect!(device);
                                    ref
                                        .read(
                                          loadingProvider(
                                            device.id,
                                          ).notifier,
                                        )
                                        .toggle(false);
                                  }
                                }
                              },
                      child: Text(
                        "Connect",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: ColorManager.accent,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
