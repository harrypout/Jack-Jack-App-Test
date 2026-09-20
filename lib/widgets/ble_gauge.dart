import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/status_colors.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class BLEGauge extends StatefulWidget {
  final String? deviceId;
  final String selectedDevice;
  final int? selectedValue;
  final Stream<int>? valueStream;
  final DateTime? lastAlertAt;

  const BLEGauge({
    super.key,
    required this.deviceId,
    required this.selectedDevice,
    this.valueStream,
    required this.selectedValue,
    this.lastAlertAt,
  });

  @override
  State<BLEGauge> createState() => _BLEGaugeState();
}

enum _ReadingState { waiting, live, unavailable }

class _BLEGaugeState extends State<BLEGauge>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _freshnessTimeout = Duration(seconds: 2);
  static const _paintInterval = Duration(milliseconds: 66);
  static const _attackMicros = 150000.0;
  static const _decayMicros = 500000.0;
  static const _gaugeSize = 170.0;
  static const _arcThickness = 16.0;

  double? _currentValue;
  double _targetValue = 0;
  _ReadingState _readingState = _ReadingState.unavailable;
  StreamSubscription<int>? _subscription;
  Timer? _freshnessTimer;
  late final Ticker _animationTicker;
  Duration _lastPaint = Duration.zero;
  int _streamGeneration = 0;
  bool _streamEnded = false;
  bool _appResumed = true;
  bool _tickerEnabled = true;
  bool _reduceMotion = false;

  bool get _visible => _appResumed && _tickerEnabled;
  bool get _canReceive =>
      widget.deviceId != null && widget.valueStream != null && !_streamEnded;
  bool get _hasThreshold =>
      widget.selectedValue != null &&
      widget.selectedValue! > 0 &&
      widget.selectedValue! <= 120;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appResumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _animationTicker = createTicker(_animate);
    _bindStream();
  }

  void _clearReading(_ReadingState state) {
    _animationTicker.stop();
    _freshnessTimer?.cancel();
    _currentValue = null;
    _targetValue = 0;
    _readingState = state;
  }

  void _awaitFreshReading() {
    _clearReading(
      _canReceive ? _ReadingState.waiting : _ReadingState.unavailable,
    );
    if (_visible && _canReceive) _armFreshnessTimer();
  }

  void _bindStream() {
    final generation = ++_streamGeneration;
    _subscription?.cancel();
    _subscription = null;
    _streamEnded = false;
    _awaitFreshReading();
    if (!_canReceive) return;

    bool isCurrent() => mounted && generation == _streamGeneration;
    try {
      _subscription = widget.valueStream!.listen(
        (value) {
          if (isCurrent()) _onValue(value);
        },
        onError: (Object error, StackTrace stack) {
          if (isCurrent()) _markUnavailable();
        },
        onDone: () {
          if (!isCurrent()) return;
          _streamEnded = true;
          _markUnavailable();
        },
      );
    } catch (_) {
      _streamEnded = true;
      _clearReading(_ReadingState.unavailable);
    }
  }

  void _armFreshnessTimer() {
    _freshnessTimer?.cancel();
    _freshnessTimer = Timer(_freshnessTimeout, _markUnavailable);
  }

  void _markUnavailable() {
    if (!mounted) return;
    if (_visible) {
      setState(() => _clearReading(_ReadingState.unavailable));
    } else {
      _clearReading(_ReadingState.unavailable);
    }
  }

  void _onValue(int value) {
    // This only pauses display work. The alert subscriptions and firmware
    // controls are owned separately and are never changed by this widget.
    if (!_visible) return;
    _armFreshnessTimer();
    _targetValue = value.toDouble();
    if (_currentValue == null || _reduceMotion) {
      _animationTicker.stop();
      setState(() {
        // The first real reading must not rise from an invented zero or from
        // another device's measurement.
        _currentValue = _targetValue;
        _readingState = _ReadingState.live;
      });
    } else if (!_animationTicker.isActive && _currentValue != _targetValue) {
      _lastPaint = Duration.zero;
      _animationTicker.start();
    }
  }

  void _animate(Duration elapsed) {
    final step = elapsed - _lastPaint;
    if (step < _paintInterval || !_visible || _currentValue == null) return;
    _lastPaint = elapsed;
    final delta = _targetValue - _currentValue!;
    final tau = delta > 0 ? _attackMicros : _decayMicros;
    // Elapsed-time smoothing preserves the response when a frame is delayed.
    // The 0.5 s falling time constant settles a 90 -> 43 change within 1 dB
    // in about two seconds. Rendering stays bounded to roughly 15 updates/s.
    var next =
        _currentValue! + delta * (1 - math.exp(-step.inMicroseconds / tau));
    if ((_targetValue - next).abs() < 0.5) {
      next = _targetValue;
      _animationTicker.stop();
    }
    setState(() => _currentValue = next);
  }

  @override
  void didUpdateWidget(BLEGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId ||
        oldWidget.valueStream != widget.valueStream) {
      _bindStream();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wasVisible = _visible;
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_visible != wasVisible) _awaitFreshReading();
    if (_reduceMotion && _currentValue != null) {
      _animationTicker.stop();
      _currentValue = _targetValue;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    if (resumed == _appResumed) return;
    setState(() {
      _appResumed = resumed;
      // Returning to the screen always requires a newly received packet.
      _awaitFreshReading();
    });
  }

  @override
  void dispose() {
    ++_streamGeneration;
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _freshnessTimer?.cancel();
    _animationTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedValue = _currentValue?.round();
    final band = gaugeLevelBand(
      displayedValue?.toDouble(),
      widget.selectedValue,
    );
    final status = switch (_readingState) {
      _ReadingState.waiting => 'Waiting for reading',
      _ReadingState.unavailable => 'No recent data',
      _ReadingState.live => _hasThreshold ? band.label : 'Live sound level',
    };
    final thresholdLabel =
        _hasThreshold
            ? 'Threshold · ${widget.selectedValue} dB'
            : 'Alert setting unavailable';
    String? alertLabel;
    if (widget.lastAlertAt case final receivedAt?) {
      final local = receivedAt.toLocal();
      final strings = MaterialLocalizations.of(context);
      final date = strings.formatShortDate(local);
      final time = strings.formatTimeOfDay(
        TimeOfDay.fromDateTime(local),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
      alertLabel = 'Last recorded alert · $date, $time';
    }

    return Semantics(
      key: const ValueKey('meter-reading'),
      container: true,
      excludeSemantics: true,
      label: widget.selectedDevice,
      // No live-region announcements on every animation frame.
      value: [
        if (displayedValue != null) '$displayedValue decibels',
        status,
        thresholdLabel,
        if (alertLabel != null) alertLabel,
      ].join('. '),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _gaugeSize,
            width: _gaugeSize,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  startAngle: 135,
                  endAngle: 45,
                  minimum: 0,
                  maximum: 120,
                  showTicks: false,
                  showLabels: false,
                  radiusFactor: 1,
                  axisLineStyle: AxisLineStyle(
                    thickness: _arcThickness,
                    color:
                        displayedValue == null
                            ? ColorManager.slate20
                            : ColorManager.inactiveGauge,
                    cornerStyle: CornerStyle.bothCurve,
                  ),
                  pointers: <GaugePointer>[
                    if (_currentValue != null)
                      RangePointer(
                        value: _currentValue!.clamp(0, 120).toDouble(),
                        width: _arcThickness,
                        color: band.color,
                        cornerStyle: CornerStyle.bothCurve,
                        enableAnimation: false,
                      ),
                    if (_hasThreshold)
                      MarkerPointer(
                        value: widget.selectedValue!.toDouble(),
                        markerType: MarkerType.circle,
                        markerHeight: 11,
                        markerWidth: 11,
                        color: ColorManager.white,
                        borderColor: ColorManager.sage,
                        borderWidth: 2.5,
                      ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      angle: 90,
                      positionFactor: 0,
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayedValue?.toString() ?? '—',
                            style: ThemeManager.gaugeValue,
                          ),
                          const Text(
                            'dB',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ColorManager.slate60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            widget.selectedDevice,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ThemeManager.rowLabel,
          ),
          const SizedBox(height: 4),
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: ColorManager.slate),
          ),
          const SizedBox(height: 2),
          Text(
            thresholdLabel,
            textAlign: TextAlign.center,
            style: ThemeManager.meta,
          ),
          if (alertLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              alertLabel,
              textAlign: TextAlign.center,
              style: ThemeManager.meta,
            ),
          ],
        ],
      ),
    );
  }
}
