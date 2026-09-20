import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/screens/manual_monitoring/providers/manual_monitoring_provider.dart';
import '../support/app_test_harness.dart';

// Live listening is deferred, but lifecycle code still uses this provider.
// Timer guards remain relevant while its UI is being removed.
void main() {
  final harness = AppTestHarness()..install();

  test('countdown starts playback once, only when its deadline is reached', () {
    fakeAsync((time) {
      final connected = FakeConnectedDevices({});
      final container = harness.container(connected: connected);
      final monitoring = container.read(manualMonitoringProvider.notifier);
      monitoring.startCountdown(true);
      time.elapse(const Duration(seconds: 4));
      expect(connected.playCalls, 0);
      expect(container.read(manualMonitoringProvider).remainingTime, 1);
      time.elapse(const Duration(seconds: 1));
      expect(connected.playCalls, 1);
      expect(container.read(manualMonitoringProvider).isStreaming, isTrue);
      time.elapse(const Duration(seconds: 2));
      expect(connected.playCalls, 1);
      monitoring.stopStreaming();
      container.dispose();
    });
  });
  test('background timer pause/resume preserves elapsed playback duration', () {
    fakeAsync((time) {
      final connected = FakeConnectedDevices({});
      final container = harness.container(connected: connected);
      final monitoring = container.read(manualMonitoringProvider.notifier);
      monitoring.startStreaming();
      time.elapse(const Duration(seconds: 3));
      monitoring.pauseTimer();
      time.elapse(const Duration(seconds: 20));
      expect(container.read(manualMonitoringProvider).streamingDuration, 3);
      monitoring.resumeStreaming(23);
      time.elapse(const Duration(seconds: 2));
      expect(container.read(manualMonitoringProvider).streamingDuration, 25);
      expect(connected.playCalls, 1);
      monitoring.stopStreaming();
      container.dispose();
    });
  });
  test('JJ-05: stopping a countdown prevents playback at its old deadline', () {
    fakeAsync((time) {
      final connected = FakeConnectedDevices({});
      final container = harness.container(connected: connected);
      final monitoring = container.read(manualMonitoringProvider.notifier);
      try {
        monitoring.startCountdown(true);
        time.elapse(const Duration(seconds: 1));
        monitoring.stopStreaming();
        time.elapse(const Duration(seconds: 5));
        expect(connected.playCalls, 0);
        expect(container.read(manualMonitoringProvider).isStreaming, isFalse);
      } finally {
        monitoring.stopStreaming();
        container.dispose();
      }
    });
  });
}
