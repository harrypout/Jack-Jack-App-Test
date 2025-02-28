// ignore_for_file: use_build_context_synchronously

import 'package:ble/screens/onboarding/pods/onboarding_status_provider.dart';
import 'package:ble/screens/onboarding/widgets/onboarding_overlay_clipper.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:ble/widgets/ble_background.dart';
import 'package:ble/widgets/ble_bottom_bar.dart';
import 'package:ble/widgets/ble_filled_button.dart';
import 'package:ble/widgets/ble_outlined_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerWidget {
  static const String id = 'onboarding_screen';
  static const List<String> titles = [
    'Welcome to Sound Sensing App',
    'Seamless Device Connection',
    'Live Sound Monitoring',
  ];
  static const List<String> subtitles = [
    'Quickly connect to your sound sensing device via Bluetooth and gain instant access to real-time sound levels, live audio monitoring, and alerts.',
    'Effortlessly connect your sound-sensing device via Bluetooth and start monitoring sound levels in real time & ensures a hassle-free setup.',
    'Experience real-time audio streaming from your device, allowing you to monitor sound levels with precision and take control with live audio playback anytime.',
  ];
  static const animationDurationInMilliseconds = 200;
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPage = ref.watch(onboardingStatusProvider);
    return Scaffold(
      body: BLEBackground(
        secondChild: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 325, //370
              child: ClipPath(
                clipper: OnboardingOverlayClipper(),
                child: Container(
                  color: ColorManager.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: animationDurationInMilliseconds,
                        ),
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            titles[selectedPage],
                            key: ValueKey<int>(selectedPage),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: ColorManager.primaryText,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: animationDurationInMilliseconds,
                        ),
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            subtitles[selectedPage],
                            key: ValueKey<int>(selectedPage),
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: ColorManager.tertiaryText,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          bool isSelected = selectedPage == index;
                          return AnimatedContainer(
                            duration: const Duration(
                              milliseconds: animationDurationInMilliseconds,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 16,
                            height: 16,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds:
                                        animationDurationInMilliseconds,
                                  ),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        isSelected
                                            ? ColorManager.accent
                                            : ColorManager.transparent,
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds:
                                        animationDurationInMilliseconds,
                                  ),
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ColorManager.white,
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds:
                                        animationDurationInMilliseconds,
                                  ),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        isSelected
                                            ? ColorManager.accent
                                            : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (selectedPage < 2)
                            BLEOutlinedButton(data: 'Skip', onPressed: () async {
                              if (await ref
                                    .read(onboardingStatusProvider.notifier)
                                    .next(skip: true)) {
                                  Navigator.pushNamed(context, BLEBottomBar.id);
                                }
                            }),
                          SizedBox(
                            width:
                                selectedPage > 1
                                    ? MediaQuery.of(context).size.width - 48
                                    : null,
                            child: BLEFilledButton(
                              data:
                                  selectedPage > 1 ? 'Get Started' : 'Continue',
                              maxButton: selectedPage > 1,
                              onPressed: () async {
                                if (await ref
                                    .read(onboardingStatusProvider.notifier)
                                    .next()) {
                                  Navigator.pushNamed(context, BLEBottomBar.id);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: animationDurationInMilliseconds,
                ),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Image.asset(
                  "assets/pngs/onboarding$selectedPage.png",
                  key: ValueKey<int>(selectedPage),
                  fit: BoxFit.fitWidth,
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.7,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
