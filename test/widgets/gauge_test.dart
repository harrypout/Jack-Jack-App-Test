import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/widgets/ble_gauge.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/status_colors.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

Widget gauge(
  Stream<int>? stream, {
  String? deviceId = 'jack-jack-a',
  String name = 'Nursery',
  int? threshold = 75,
  bool reduceMotion = false,
  bool visible = true,
  double textScale = 1,
  DateTime? lastAlertAt,
}) => ProviderScope(
  child: MaterialApp(
    home: Builder(
      builder:
          (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
              textScaler: TextScaler.linear(textScale),
            ),
            child: TickerMode(
              enabled: visible,
              child: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: BLEGauge(
                      key: const ValueKey('current-device-gauge'),
                      deviceId: deviceId,
                      selectedDevice: name,
                      selectedValue: threshold,
                      valueStream: stream,
                      lastAlertAt: lastAlertAt,
                    ),
                  ),
                ),
              ),
            ),
          ),
    ),
  ),
);

// Deliver asynchronous BLE callbacks before rendering or advancing the clock.
Future<void> flushFrame(WidgetTester tester) async {
  await tester.idle();
  await tester.pump();
}

List<GaugePointer> pointers(WidgetTester tester) =>
    tester
        .widget<SfRadialGauge>(find.byType(SfRadialGauge))
        .axes
        .first
        .pointers!;

double reading(WidgetTester tester) =>
    pointers(tester).whereType<RangePointer>().single.value;

void testMeter(
  String description,
  Future<void> Function(WidgetTester, StreamController<int>) body,
) {
  testWidgets(description, (tester) async {
    final input = StreamController<int>.broadcast();
    try {
      await body(tester, input);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await input.close();
    }
  });
}

Future<void> sustain(
  WidgetTester tester,
  StreamController<int> input,
  int value,
  int milliseconds,
) async {
  for (var elapsed = 0; elapsed < milliseconds; elapsed += 100) {
    input.add(value);
    await flushFrame(tester);
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testMeter(
    'no first packet shows waiting, then unavailable, never a fabricated zero',
    (tester, input) async {
      await tester.pumpWidget(gauge(input.stream));
      expect(find.text('Waiting for reading'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(pointers(tester).whereType<RangePointer>(), isEmpty);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('No recent data'), findsOneWidget);
    },
  );

  testMeter(
    'gauge renders the first actual reading and releases its listener on disposal',
    (tester, input) async {
      await tester.pumpWidget(gauge(input.stream));
      input.add(75);
      await flushFrame(tester);
      expect(find.text('75'), findsOneWidget);
      expect(find.text('Nursery'), findsOneWidget);
      expect(reading(tester), 75);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(input.hasListener, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testMeter(
    'meter responds to a sustained rise without changing the alert setting',
    (tester, input) async {
      await tester.pumpWidget(gauge(input.stream));
      input.add(43);
      await flushFrame(tester);
      input.add(90);
      await flushFrame(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(reading(tester), inInclusiveRange(75, 90));
      expect(pointers(tester).whereType<MarkerPointer>().single.value, 75);
      expect(find.text('Threshold · 75 dB'), findsOneWidget);
    },
  );

  testMeter(
    'falling level settles within one dB in two seconds while quiet packets continue',
    (tester, input) async {
      await tester.pumpWidget(gauge(input.stream));
      input.add(90);
      await flushFrame(tester);
      await sustain(tester, input, 43, 2000);
      expect(reading(tester), inInclusiveRange(43, 44));
      expect(find.text('Below alert setting'), findsOneWidget);
    },
  );

  testMeter(
    'a delayed frame uses elapsed time rather than extending the falling animation',
    (tester, input) async {
      await tester.pumpWidget(gauge(input.stream));
      input.add(90);
      await flushFrame(tester);
      input.add(43);
      await flushFrame(tester);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(reading(tester), inInclusiveRange(43, 46));
    },
  );

  testMeter(
    'freshness expires at two seconds and recovery starts with the new actual reading',
    (tester, input) async {
      await tester.pumpWidget(gauge(input.stream));
      input.add(90);
      await flushFrame(tester);
      await tester.pump(const Duration(milliseconds: 1999));
      expect(find.text('90'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('No recent data'), findsOneWidget);
      expect(find.text('90'), findsNothing);
      expect(pointers(tester).whereType<RangePointer>(), isEmpty);
      input.add(43);
      await flushFrame(tester);
      expect(find.text('43'), findsOneWidget);
      expect(reading(tester), 43);
    },
  );

  testMeter(
    'each new packet refreshes freshness even when the value is unchanged',
    (tester, input) async {
      await tester.pumpWidget(gauge(input.stream));
      await sustain(tester, input, 43, 6000);
      expect(find.text('43'), findsOneWidget);
      expect(find.text('No recent data'), findsNothing);
    },
  );

  testMeter(
    'JJ-12: clearing the selected stream detaches and ignores the previous device',
    (tester, input) async {
      await tester.pumpWidget(gauge(input.stream));
      input.add(90);
      await flushFrame(tester);
      await tester.pumpWidget(gauge(null, deviceId: null, name: 'No device'));
      expect(input.hasListener, isFalse);
      input.add(75);
      await flushFrame(tester);
      expect(find.text('No recent data'), findsOneWidget);
      expect(pointers(tester).whereType<RangePointer>(), isEmpty);
    },
  );

  testMeter(
    'JJ-12: switching streams cannot label the old reading with the new name',
    (tester, input) async {
      final second = StreamController<int>.broadcast();
      try {
        await tester.pumpWidget(gauge(input.stream));
        input.add(90);
        await flushFrame(tester);
        expect(find.text('90'), findsOneWidget);
        await tester.pumpWidget(gauge(second.stream, name: 'Travel cot'));
        expect(find.text('Travel cot'), findsOneWidget);
        expect(find.text('90'), findsNothing);
        expect(find.text('Waiting for reading'), findsOneWidget);
        expect(input.hasListener, isFalse);
        second.add(43);
        await flushFrame(tester);
        expect(reading(tester), 43);
      } finally {
        await second.close();
      }
    },
  );

  testMeter(
    'stable device identity resets a reading even if names and stream objects match',
    (tester, input) async {
      await tester.pumpWidget(gauge(input.stream));
      input.add(90);
      await flushFrame(tester);
      await tester.pumpWidget(gauge(input.stream, deviceId: 'jack-jack-b'));
      expect(find.text('90'), findsNothing);
      expect(find.text('Waiting for reading'), findsOneWidget);
      input.add(43);
      await flushFrame(tester);
      expect(reading(tester), 43);
    },
  );

  testMeter('renaming the same device preserves its current live reading', (
    tester,
    input,
  ) async {
    await tester.pumpWidget(gauge(input.stream));
    input.add(75);
    await flushFrame(tester);
    await tester.pumpWidget(gauge(input.stream, name: 'Bedroom'));
    expect(find.text('Bedroom'), findsOneWidget);
    expect(reading(tester), 75);
  });

  testMeter(
    'stream errors remove the reading and a later valid packet recovers',
    (tester, input) async {
      await tester.pumpWidget(gauge(input.stream));
      input.add(75);
      await flushFrame(tester);
      input.addError(StateError('BLE interrupted'));
      await flushFrame(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('No recent data'), findsOneWidget);
      expect(pointers(tester).whereType<RangePointer>(), isEmpty);
      input.add(43);
      await flushFrame(tester);
      expect(reading(tester), 43);
    },
  );

  testMeter('a completed stream immediately removes its last reading', (
    tester,
    input,
  ) async {
    await tester.pumpWidget(gauge(input.stream));
    input.add(75);
    await flushFrame(tester);
    unawaited(input.close());
    await flushFrame(tester);
    expect(find.text('No recent data'), findsOneWidget);
    expect(pointers(tester).whereType<RangePointer>(), isEmpty);
  });

  testMeter('Reduce Motion shows new samples directly without a tween', (
    tester,
    input,
  ) async {
    await tester.pumpWidget(gauge(input.stream, reduceMotion: true));
    input.add(43);
    await flushFrame(tester);
    input.add(90);
    await flushFrame(tester);
    expect(reading(tester), 90);
    input.add(43);
    await flushFrame(tester);
    expect(reading(tester), 43);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testMeter(
    'a hidden route pauses visual work and requires fresh input on return',
    (tester, input) async {
      await tester.pumpWidget(gauge(input.stream));
      input.add(43);
      await flushFrame(tester);
      input.add(90);
      await flushFrame(tester);
      await tester.pumpWidget(gauge(input.stream, visible: false));
      expect(input.hasListener, isTrue);
      input.add(90);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(gauge(input.stream));
      expect(find.text('Waiting for reading'), findsOneWidget);
      expect(pointers(tester).whereType<RangePointer>(), isEmpty);
      input.add(43);
      await flushFrame(tester);
      expect(reading(tester), 43);
    },
  );

  testMeter(
    'app backgrounding pauses visuals without closing the shared sound stream',
    (tester, input) async {
      try {
        await tester.pumpWidget(gauge(input.stream));
        input.add(90);
        await flushFrame(tester);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await flushFrame(tester);
        input.add(90);
        await tester.pump(const Duration(seconds: 3));
        expect(input.hasListener, isTrue);
        expect(tester.binding.transientCallbackCount, 0);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await flushFrame(tester);
        expect(find.text('Waiting for reading'), findsOneWidget);
        input.add(43);
        await flushFrame(tester);
        expect(reading(tester), 43);
      } finally {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      }
    },
  );

  testMeter(
    'the displayed number, colour and text use the same threshold boundary',
    (tester, input) async {
      await tester.pumpWidget(gauge(input.stream));
      input.add(75);
      await flushFrame(tester);
      expect(find.text('At or above alert setting'), findsOneWidget);
      expect(
        pointers(tester).whereType<RangePointer>().single.color,
        ColorManager.coral,
      );
      await tester.pumpWidget(gauge(input.stream, threshold: 80));
      expect(find.text('Near alert setting'), findsOneWidget);
      expect(
        pointers(tester).whereType<RangePointer>().single.color,
        ColorManager.yellow,
      );
    },
  );

  testMeter('an unknown threshold is not drawn as a zero setting', (
    tester,
    input,
  ) async {
    await tester.pumpWidget(gauge(input.stream, threshold: null));
    input.add(43);
    await flushFrame(tester);
    expect(find.text('Alert setting unavailable'), findsOneWidget);
    expect(pointers(tester).whereType<MarkerPointer>(), isEmpty);
    expect(reading(tester), 43);
  });

  testMeter(
    'the last recorded alert stays distinct when sound becomes quiet or stale',
    (tester, input) async {
      await tester.pumpWidget(
        gauge(input.stream, lastAlertAt: DateTime(2026, 9, 13, 12)),
      );
      input.add(43);
      await flushFrame(tester);
      expect(find.text('Below alert setting'), findsOneWidget);
      expect(find.textContaining('Last recorded alert ·'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('No recent data'), findsOneWidget);
      expect(find.textContaining('Last recorded alert ·'), findsOneWidget);
    },
  );

  testMeter(
    'accessible meter summary describes level, device and threshold without colour alone',
    (tester, input) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(gauge(input.stream));
        input.add(72);
        await flushFrame(tester);
        final node = tester.getSemantics(
          find.byKey(const ValueKey('meter-reading')),
        );
        expect(node.label, 'Nursery');
        expect(node.value, contains('72 decibels'));
        expect(node.value, contains('Near alert setting'));
        expect(node.value, contains('Threshold · 75 dB'));
      } finally {
        semantics.dispose();
      }
    },
  );

  testMeter('meter remains usable with large text on a narrow phone', (
    tester,
    input,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      gauge(
        input.stream,
        textScale: 2,
        name: 'Nursery with a long device name',
        lastAlertAt: DateTime(2026, 9, 13, 12),
      ),
    );
    input.add(90);
    await flushFrame(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('At or above alert setting'), findsOneWidget);
  });

  test(
    'near-threshold colour uses a fixed five-dB band at different settings',
    () {
      for (final threshold in [40, 75, 100]) {
        expect(
          gaugeLevelBand(threshold - 5.01, threshold),
          GaugeLevelBand.below,
        );
        expect(gaugeLevelBand(threshold - 5, threshold), GaugeLevelBand.near);
        expect(
          gaugeLevelBand(threshold - 0.01, threshold),
          GaugeLevelBand.near,
        );
        expect(
          gaugeLevelBand(threshold.toDouble(), threshold),
          GaugeLevelBand.above,
        );
      }
      expect(gaugeLevelBand(null, 75), GaugeLevelBand.unknown);
      expect(gaugeLevelBand(75, null), GaugeLevelBand.unknown);
      expect(gaugeLevelBand(75, 0), GaugeLevelBand.unknown);
      expect(gaugeLevelBand(75, 121), GaugeLevelBand.unknown);
    },
  );
}
