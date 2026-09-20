// ignore_for_file: use_build_context_synchronously

import 'package:jackjack/main.dart';
import 'package:jackjack/screens/onboarding/pods/onboarding_status_provider.dart';
import 'package:jackjack/screens/onboarding/widgets/onboarding_hero_connect.dart';
import 'package:jackjack/screens/onboarding/widgets/onboarding_hero_monitor.dart';
import 'package:jackjack/screens/onboarding/widgets/onboarding_hero_welcome.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_bottom_bar.dart';
import 'package:jackjack/widgets/ble_filled_button.dart';
import 'package:jackjack/widgets/ble_outlined_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerWidget {
  static const String id = 'onboarding_screen';
  static const List<String> titles = [
    'Meet Jack Jack',
    'Connect your Pebble',
    'See the sound level',
  ];
  static const List<String> subtitles = [
    'Your Pebble measures sound in the room and can alert your phone when the sound stays above your chosen threshold.',
    'Turn on Bluetooth, keep your Pebble nearby, and connect it in the app. No account or internet connection is needed.',
    'Watch the sound meter, set a threshold that fits your room, and review recorded sound alerts. Keep Bluetooth and phone notifications enabled.',
  ];

  const OnboardingScreen({super.key});

  Widget _fadeRise(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder:
            (context, child) => Transform.translate(
              offset: Offset(0, (1 - animation.value) * 6),
              child: child,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPage = ref.watch(onboardingStatusProvider);
    const heroes = [
      OnboardingHeroWelcome(),
      OnboardingHeroConnect(),
      OnboardingHeroMonitor(),
    ];

    return Scaffold(
      body: Column(
        children: [
          // Hero stage on a soft radial sage wash.
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.64),
                  radius: 1.2,
                  colors: [ColorManager.sageTint10, ColorManager.transparent],
                  stops: [0, 0.7],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: ThemeManager.durPage,
                    switchInCurve: Curves.ease,
                    transitionBuilder: _fadeRise,
                    child: KeyedSubtree(
                      key: ValueKey<int>(selectedPage),
                      child: heroes[selectedPage],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // White sheet with 34px top corners.
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: ColorManager.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              boxShadow: ThemeManager.sheetShadow,
            ),
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 0),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: ThemeManager.durPage,
                    switchInCurve: Curves.ease,
                    transitionBuilder: _fadeRise,
                    child: Text(
                      titles[selectedPage],
                      key: ValueKey<int>(selectedPage),
                      style: ThemeManager.displayOnboardingTitle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: AnimatedSwitcher(
                      duration: ThemeManager.durPage,
                      switchInCurve: Curves.ease,
                      transitionBuilder: _fadeRise,
                      child: Text(
                        subtitles[selectedPage],
                        key: ValueKey<int>(selectedPage),
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.55,
                          color: ColorManager.slate70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isSelected = selectedPage == index;
                      return GestureDetector(
                        onTap:
                            () => ref
                                .read(onboardingStatusProvider.notifier)
                                .setPage(index),
                        child: AnimatedContainer(
                          duration: ThemeManager.durDots,
                          curve: Curves.ease,
                          margin: const EdgeInsets.symmetric(horizontal: 3.5),
                          width: isSelected ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: ThemeManager.brFull,
                            color:
                                isSelected
                                    ? ColorManager.sage
                                    : ColorManager.slate20,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (selectedPage < 2) ...[
                        BLEOutlinedButton(
                          data: 'Skip',
                          onPressed: () async {
                            Navigator.pushNamed(context, BLEBottomBar.id);
                            prefs.setBool('onboarding_status', true);
                          },
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: BLEFilledButton(
                          data: selectedPage > 1 ? 'Get Started' : 'Continue',
                          maxButton: true,
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
        ],
      ),
    );
  }
}
