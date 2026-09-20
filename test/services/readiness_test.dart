import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/services/app_initializer.dart';
import '../support/app_test_harness.dart';

void main() {
  AppTestHarness().install();
  test(
    'JJ-11: Bluetooth denial prevents the ready state and scanning',
    () async {
      final container = ProviderContainer(
        overrides: [
          readinessChecksProvider.overrideWithValue(
            ReadinessChecks(
              bluetooth: (_) async => false,
              notifications: (_) async => true,
              initialize: () async {},
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final phase = await container.read(appInitializerProvider.future);
      expect(phase, InitPhase.bluetoothDenied);
      expect(canUseBluetooth(phase), false);
    },
  );
  test(
    'JJ-11: notification denial is visible but local BLE history remains possible',
    () async {
      final container = ProviderContainer(
        overrides: [
          readinessChecksProvider.overrideWithValue(
            ReadinessChecks(
              bluetooth: (_) async => true,
              notifications: (_) async => false,
              initialize: () async {},
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final phase = await container.read(appInitializerProvider.future);
      expect(phase, InitPhase.notificationsDenied);
      expect(canUseBluetooth(phase), true);
    },
  );
  test(
    'JJ-11: initialization errors are not reported as ready and retry can recover',
    () async {
      var fail = true;
      final container = ProviderContainer(
        overrides: [
          readinessChecksProvider.overrideWithValue(
            ReadinessChecks(
              bluetooth: (_) async => true,
              notifications: (_) async => true,
              initialize: () async {
                if (fail) throw StateError('plugin unavailable');
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(appInitializerProvider.future),
        throwsStateError,
      );
      expect(container.read(appInitializerProvider).hasError, true);
      fail = false;
      await container.read(appInitializerProvider.notifier).retry();
      expect(container.read(appInitializerProvider).value, InitPhase.complete);
    },
  );
  test(
    'JJ-11: resume checks revoked permission without showing a new prompt',
    () async {
      var granted = true;
      final prompts = <bool>[];
      final container = ProviderContainer(
        overrides: [
          readinessChecksProvider.overrideWithValue(
            ReadinessChecks(
              bluetooth: (request) async {
                prompts.add(request);
                return granted;
              },
              notifications: (_) async => true,
              initialize: () async {},
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(appInitializerProvider.future);
      granted = false;
      await container
          .read(appInitializerProvider.notifier)
          .retry(requestPermissions: false);
      expect(prompts, [true, false]);
      expect(
        container.read(appInitializerProvider).value,
        InitPhase.bluetoothDenied,
      );
    },
  );
}
