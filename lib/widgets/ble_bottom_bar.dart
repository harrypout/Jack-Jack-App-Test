import 'package:jackjack/providers/navigation_provider.dart';
import 'package:jackjack/utils/platform_channel_manager.dart';
import 'package:jackjack/screens/home/home_screen.dart';
import 'package:jackjack/screens/pairing/pairing_screen.dart';
import 'package:jackjack/screens/settings/settings_screen.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class BLEBottomBar extends ConsumerStatefulWidget {
  static const String id = 'ble_bottom_bar';
  const BLEBottomBar({super.key});

  @override
  ConsumerState createState() => _BLEBottomBarState();
}

class _BLEBottomBarState extends ConsumerState<BLEBottomBar> {
  @override
  Widget build(BuildContext context) {
    final selectedScreenIndex = ref.watch(navigationProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          PlatformChannelManager.moveToBackground();
        }
      },
      child: Scaffold(
        body:
            <Widget>[
              const HomeScreen(),
              const PairingScreen(),
              const SettingsScreen(),
            ][selectedScreenIndex],
        bottomNavigationBar: const ColoredBox(
          color: ColorManager.white,
          child: SafeArea(top: false, child: CustomBottomNav()),
        ),
      ),
    );
  }
}

class CustomBottomNav extends ConsumerWidget {
  const CustomBottomNav({super.key});

  // Geometry derives from these four; the composites stay in sync.
  static const double _barHeight = 62;
  static const double _fabOverhang = 24;
  static const double _fabButtonSize = 56;
  static const double _ringWidth = 4;
  static const double _fabSize = _fabButtonSize + 2 * _ringWidth;
  static const double _navHeight = _barHeight + _fabOverhang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final extraLabelHeight = MediaQuery.textScalerOf(context).scale(12) - 12;
    var selectedScreenIndex = ref.watch(navigationProvider);
    return SizedBox(
      width: size.width,
      height: _navHeight + extraLabelHeight + 6,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: _barHeight + extraLabelHeight + 6,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: ColorManager.white,
                border: Border(top: BorderSide(color: ColorManager.slate10)),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: NavBarButton(
                      index: 1,
                      title: "Connect",
                      icon: "scanner",
                    ),
                  ),
                  SizedBox(width: 72),
                  Expanded(
                    child: NavBarButton(
                      index: 2,
                      title: "Settings",
                      icon: "setting",
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: _fabSize,
                height: _fabSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorManager.accent,
                  // Page-background ring separating the FAB from the bar.
                  border: Border.all(
                    color: ColorManager.background,
                    width: _ringWidth,
                  ),
                  boxShadow:
                      selectedScreenIndex == 0
                          ? ThemeManager.sageGlow
                          : ThemeManager.shadowMd,
                ),
                child: Semantics(
                  label: 'Home',
                  selected: selectedScreenIndex == 0,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(navigationProvider.notifier).toggle(0);
                    },
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
                      minimumSize: WidgetStateProperty.all(
                        Size(_fabButtonSize, _fabButtonSize),
                      ),
                      backgroundColor: const WidgetStatePropertyAll<Color?>(
                        ColorManager.transparent,
                      ),
                      shadowColor: const WidgetStatePropertyAll<Color?>(
                        ColorManager.transparent,
                      ),
                      elevation: WidgetStateProperty.all(0.0),
                      shape: WidgetStateProperty.all(const CircleBorder()),
                    ),
                    child: SvgPicture.asset(
                      "assets/svgs/home${selectedScreenIndex == 0 ? "_filled" : ""}.svg",
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        ColorManager.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: ExcludeSemantics(
              child: Center(
                child: Text(
                  'Home',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        selectedScreenIndex == 0
                            ? FontWeight.w700
                            : FontWeight.w400,
                    color:
                        selectedScreenIndex == 0
                            ? ColorManager.accent
                            : ColorManager.slate60,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NavBarButton extends ConsumerWidget {
  final int index;
  final String title;
  final String icon;
  final Color color;
  final void Function()? onPressed;
  const NavBarButton({
    super.key,
    required this.index,
    required this.title,
    required this.icon,
    this.color = ColorManager.slate60,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var selectedScreenIndex = ref.watch(navigationProvider);
    final active = selectedScreenIndex == index;
    return ElevatedButton(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        backgroundColor: const WidgetStatePropertyAll<Color?>(
          ColorManager.transparent,
        ),
        shadowColor: const WidgetStatePropertyAll<Color?>(
          ColorManager.transparent,
        ),
        elevation: WidgetStateProperty.all(0.0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: ThemeManager.brLg),
        ),
        minimumSize: WidgetStatePropertyAll(Size(0, 40)),
      ),
      onPressed: () {
        ref.read(navigationProvider.notifier).toggle(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: SvgPicture.asset(
              "assets/svgs/$icon${active ? "_filled" : ""}.svg",
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                active ? ColorManager.accent : ColorManager.slate60,
                BlendMode.srcIn,
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? ColorManager.accent : ColorManager.slate60,
            ),
          ),
        ],
      ),
    );
  }
}
