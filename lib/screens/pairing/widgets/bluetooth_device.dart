import 'package:jackjack/providers/loading_provider.dart';
import 'package:jackjack/services/device_name_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/status_colors.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_bottom_sheet.dart';
import 'package:jackjack/widgets/ble_status_pill.dart';
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

  /// Presentational mapping of the already-scanned RSSI (-100..-40 dBm) to a
  /// percentage. Rows rebuilt from prefs carry rssi == 0, which would read
  /// as a false 100% — callers hide the line unless rssi < 0.
  static int signalPercent(int rssi) =>
      (((rssi + 100) * 100) / 60).clamp(0, 100).round();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(loadingProvider(device.id));
    final deviceNames = ref.watch(deviceNamesProvider);
    final displayName = deviceNames[device.id] ?? device.name;
    final tone = deviceTone(id: device.id, isPrimary: isPaired);
    final hasSignal = device.rssi < 0;

    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ColorManager.white,
        border: Border.all(color: ColorManager.containerBorder),
        borderRadius: ThemeManager.brLg,
        boxShadow: ThemeManager.shadowSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tone.tintBg,
                    borderRadius: ThemeManager.brMd,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    "assets/svgs/device.svg",
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      tone.iconColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loader ? "Device Name" : displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: ColorManager.slate,
                        ),
                      ),
                      if (hasSignal)
                        Text(
                          signalPercent(device.rssi) >= 70
                              ? "Signal strong · ${signalPercent(device.rssi)}%"
                              : "Signal · ${signalPercent(device.rssi)}%",
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ColorManager.slate60,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Skeletonizer(
            enabled: isLoading,
            child:
                isPaired
                    ? TextButton(
                      onPressed:
                          loader
                              ? null
                              : () {
                                BLEBottomSheet.openSheet(
                                  context,
                                  PairedInfoBottomSheet(device: device),
                                );
                              },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const BLEStatusPill("Paired"),
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
                                          loadingProvider(device.id).notifier,
                                        )
                                        .toggle(true);
                                    await onConnect!(device);
                                    ref
                                        .read(
                                          loadingProvider(device.id).notifier,
                                        )
                                        .toggle(false);
                                  }
                                }
                              },
                      child: Text(
                        "Connect ›",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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
