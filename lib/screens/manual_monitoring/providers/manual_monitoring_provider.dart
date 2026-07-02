import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:jackjack/providers/connected_devices_provider.dart';
import 'package:jackjack/utils/toast_manager.dart';

part 'manual_monitoring_provider.g.dart';

class ManualMonitoringState {
  final bool isStreaming;
  final bool showCountdown;
  final int remainingTime;
  final int streamingDuration;
  final Timer? countdownTimer;
  final Timer? streamingTimer;

  ManualMonitoringState({
    this.isStreaming = false,
    this.showCountdown = false,
    this.remainingTime = 5,
    this.streamingDuration = 0,
    this.countdownTimer,
    this.streamingTimer,
  });

  ManualMonitoringState copyWith({
    bool? isStreaming,
    bool? showCountdown,
    int? remainingTime,
    int? streamingDuration,
    Timer? countdownTimer,
    Timer? streamingTimer,
  }) {
    return ManualMonitoringState(
      isStreaming: isStreaming ?? this.isStreaming,
      showCountdown: showCountdown ?? this.showCountdown,
      remainingTime: remainingTime ?? this.remainingTime,
      streamingDuration: streamingDuration ?? this.streamingDuration,
      countdownTimer: countdownTimer ?? this.countdownTimer,
      streamingTimer: streamingTimer ?? this.streamingTimer,
    );
  }
}

@Riverpod(keepAlive: true)
class ManualMonitoring extends _$ManualMonitoring {
  final int countdownDuration = 5;

  @override
  ManualMonitoringState build() {
    ref.onDispose(() {
      state.countdownTimer?.cancel();
      state.streamingTimer?.cancel();
    });

    return ManualMonitoringState();
  }

  void startCountdown(bool isConnected) {
    if (!isConnected) {
      ToastManager.show("Please connect the selected device!");
      return;
    }

    state.countdownTimer?.cancel();

    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingTime > 1) {
        state = state.copyWith(
          remainingTime: state.remainingTime - 1,
        );
      } else {
        startStreaming();
      }
    });

    state = state.copyWith(
      showCountdown: true,
      remainingTime: countdownDuration,
      countdownTimer: timer,
    );
  }

  void startStreaming() {
    state.countdownTimer?.cancel();
    ref.read(connectedDevicesProvider.notifier).playAudio();

    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(
        streamingDuration: state.streamingDuration + 1,
      );
    });

    state = state.copyWith(
      showCountdown: false,
      isStreaming: true,
      streamingDuration: 0,
      streamingTimer: timer,
    );
  }

  void stopStreaming() {
    ref.read(connectedDevicesProvider.notifier).stopAudio();

    state.streamingTimer?.cancel();

    state = state.copyWith(
      isStreaming: false,
      showCountdown: false,
      streamingDuration: 0,
      streamingTimer: null,
    );
  }

  void skipCountdown() {
    startStreaming();
  }

  /// Pause the streaming timer (for background handoff)
  void pauseTimer() {
    state.streamingTimer?.cancel();
    state = state.copyWith(streamingTimer: null);
  }

  /// Resume streaming with a given duration (from background)
  void resumeStreaming(int duration) {
    // Resume with existing duration from background
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(streamingDuration: state.streamingDuration + 1);
    });

    state = state.copyWith(
      isStreaming: true,
      streamingDuration: duration,
      streamingTimer: timer,
      showCountdown: false,
    );

    // Audio is already playing (OS maintains it), no need to restart
  }
}