import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/main.dart' as app;
import 'package:jackjack/providers/navigation_provider.dart';
import 'package:jackjack/screens/settings/settings_screen.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_bottom_bar.dart';
import '../support/app_test_harness.dart';

void main() {
  AppTestHarness().install();
  final captureKey = GlobalKey();
  const capture = bool.fromEnvironment('CAPTURE_UI');
  setUpAll(() async {
    for (final (family, asset) in [
      ('Nunito Sans', 'assets/fonts/nunitosans-400.ttf'),
      ('Fredoka', 'assets/fonts/fredoka-600.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  Future<ProviderContainer> screen(
    WidgetTester tester, {
    double width = 393,
    double textScale = 1,
  }) async {
    debugDefaultTargetPlatformOverride = null;
    tester.view.physicalSize = Size(width, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(navigationProvider.notifier).toggle(2);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: captureKey,
          child: Builder(
            builder:
                (context) => MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: ThemeManager.appTheme(context),
                  builder:
                      (context, child) => MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: TextScaler.linear(textScale)),
                        child: child!,
                      ),
                  home: const Scaffold(
                    body: SettingsScreen(),
                    bottomNavigationBar: CustomBottomNav(),
                  ),
                ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> snapshot(WidgetTester tester, String name) async {
    if (!capture) return;
    await tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('coverage/ui/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> choose(WidgetTester tester, Finder menu, String choice) async {
    await tester.ensureVisible(menu);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: menu, matching: find.byType(TextField)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(choice).hitTestable().last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'Home is the centre action; Connect and Settings keep their routes',
    (tester) async {
      final container = await screen(tester);
      final home = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Home',
      );
      expect(tester.getCenter(home).dx, closeTo(393 / 2, 1));
      expect(tester.getCenter(find.text('Connect')).dx, lessThan(393 / 2));
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();
      expect(container.read(navigationProvider), 1);
      await tester.tap(home);
      await tester.pumpAndSettle();
      expect(container.read(navigationProvider), 0);
      await tester.tap(find.widgetWithText(NavBarButton, 'Settings'));
      await tester.pumpAndSettle();
      expect(container.read(navigationProvider), 2);
      await snapshot(tester, 'settings-navigation');
    },
  );

  testWidgets(
    'Settings saves each selection independently and restores saved choices',
    (tester) async {
      await screen(tester);
      await choose(tester, find.byType(DropdownMenu<Duration>), '30 seconds');
      final sounds = find.byType(DropdownMenu<String>);
      await choose(tester, sounds.at(0), 'Ping');
      await choose(tester, sounds.at(1), 'Stomachache');
      await choose(tester, sounds.at(2), 'Missile Alert');
      expect(app.prefs.getString('notificationTimeout'), '30 seconds');
      expect(app.prefs.getString('connectSound'), 'Ping');
      expect(app.prefs.getString('disconnectSound'), 'Stomachache');
      expect(app.prefs.getString('thresholdSound'), 'Missile Alert');
      await tester.pumpWidget(const SizedBox.shrink());
      await screen(tester);
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.map((field) => field.controller!.text), [
        '30 seconds',
        'Ping',
        'Stomachache',
        'Missile Alert',
      ]);
    },
  );

  testWidgets('Settings selectors fit a 320-point screen with enlarged text', (
    tester,
  ) async {
    await screen(tester, width: 320, textScale: 1.6);
    await choose(tester, find.byType(DropdownMenu<Duration>), '2 minutes');
    final sounds = find.byType(DropdownMenu<String>);
    for (var i = 0; i < 3; i++) {
      await choose(tester, sounds.at(i), 'Stomachache');
      final field = find.descendant(
        of: sounds.at(i),
        matching: find.byType(TextField),
      );
      final rect = tester.getRect(field);
      expect(rect.left, greaterThanOrEqualTo(20));
      expect(rect.right, lessThanOrEqualTo(300));
      expect(rect.height, greaterThanOrEqualTo(48));
    }
    await snapshot(tester, 'settings-large-text');
  });
}
