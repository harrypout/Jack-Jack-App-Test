import 'dart:io';
import 'package:jackjack/providers/navigation_provider.dart';
import 'package:jackjack/screens/home/home_screen.dart';
import 'package:jackjack/screens/manual_monitoring/manual_monitoring_screen.dart';
import 'package:jackjack/screens/pairing/pairing_screen.dart';
import 'package:jackjack/screens/settings/settings_screen.dart';
import 'package:jackjack/screens/threshold/threshold_screen.dart';
import 'package:jackjack/utils/color_manager.dart';
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
    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body:
              <Widget>[
                HomeScreen(),
                ThresholdScreen(),
                PairingScreen(),
                ManualMonitoringScreen(),
                SettingsScreen(),
              ][selectedScreenIndex],
          bottomNavigationBar: const SizedBox(height: 75, width: 1),
        ),
        Positioned(
          bottom: 0,
          child: Column(
            children: [
              const CustomBottomNav(),
              Platform.isIOS
                  ? Container(
                    width: MediaQuery.of(context).size.width,
                    height: 10,
                    color: ColorManager.white,
                  )
                  : Container(),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomBottomNav extends ConsumerWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var size = MediaQuery.of(context).size;
    var selectedScreenIndex = ref.watch(navigationProvider);
    return Stack(
      children: [
        CustomPaint(size: Size(size.width, 110), painter: MyCustomPainter()),
        Positioned(
          bottom: 0,
          child: Container(
            height: 75,
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    NavBarButton(index: 0, title: "Home", icon: "home"),
                    NavBarButton(
                      index: 1,
                      title: "Threshold",
                      icon: "notificationm",
                    ),
                    SizedBox(width: 45),
                    NavBarButton(
                      index: 3,
                      title: "Manual Mode",
                      icon: "toggle",
                    ),
                    NavBarButton(index: 4, title: "Settings", icon: "setting"),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                  color: ColorManager.accent,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(navigationProvider.notifier).toggle(2);
                  },
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
                    minimumSize: WidgetStateProperty.all(Size(59, 59)),
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(color: ColorManager.white),
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
                    "assets/svgs/scanner${selectedScreenIndex == 2 ? "_filled" : ""}.svg",
                    width: 24,
                    height: 24,

                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
    this.color = ColorManager.tertiaryText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var selectedScreenIndex = ref.watch(navigationProvider);
    return ElevatedButton(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(color: ColorManager.white),
        ),
        backgroundColor: const WidgetStatePropertyAll<Color?>(
          ColorManager.transparent,
        ),
        shadowColor: const WidgetStatePropertyAll<Color?>(
          ColorManager.transparent,
        ),
        elevation: WidgetStateProperty.all(0.0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
      onPressed: () {
        ref.read(navigationProvider.notifier).toggle(index);
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: SvgPicture.asset(
              "assets/svgs/$icon${selectedScreenIndex == index ? "_filled" : ""}.svg",
              width: 24,
              height: 24,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color:
                  selectedScreenIndex == index
                      ? ColorManager.accent
                      : ColorManager.tertiaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class MyCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =
        Paint()
          ..color = ColorManager.white
          ..style = PaintingStyle.fill
          ..invertColors = false;

    Rect box = Rect.fromLTRB(0, 110, size.width, 35);
    Rect box2 = Rect.fromLTRB(0, 110, size.width, 90);
    RRect roundBox = RRect.fromRectAndRadius(box, const Radius.circular(10));
    Path path = Path();
    path.addRRect(roundBox);
    path.addRect(box2);
    path.addRect(box2);

    path.moveTo((size.width * 0.5) - 45, 35);
    path.arcToPoint(
      Offset((size.width * 0.5) - 30, 42),
      radius: const Radius.circular(16),
      clockwise: true,
    );
    path.arcToPoint(
      Offset((size.width * 0.5) + 30, 42),
      radius: const Radius.circular(32),
      clockwise: false,
    );
    path.arcToPoint(
      Offset((size.width * 0.5) + 45, 35),
      radius: const Radius.circular(20),
    );

    canvas.drawShadow(
      path.shift(const Offset(0, -5)),
      Colors.black,
      10.0,
      true,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
