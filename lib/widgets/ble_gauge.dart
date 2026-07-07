import 'dart:async';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/status_colors.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class BLEGauge extends ConsumerStatefulWidget {
  final String selectedDevice;
  final int selectedValue;
  final Stream<int>? valueStream;

  const BLEGauge({
    super.key,
    required this.selectedDevice,
    this.valueStream,
    required this.selectedValue,
  });

  @override
  ConsumerState createState() => _BLEGaugeState();
}

class _BLEGaugeState extends ConsumerState<BLEGauge> {
  double _currentValue = 0.0;
  double _targetValue = 0.0;
  StreamSubscription<int>? _streamSubscription;

  // Display smoothing. The firmware notifies raw instantaneous samples, so
  // painting the latest one each frame makes the gauge jitter. Instead the
  // gauge eases toward the newest sample with a fast attack (rises register
  // in ~half a second, so a cry still reads immediately) and a slow decay
  // (falls settle over ~1.5s instead of flickering back down). Display-only:
  // threshold alerts come from a separate firmware-driven characteristic,
  // so smoothing here cannot delay or suppress an alert.
  //
  // The ~15fps tick also keeps the old repaint throttle: samples arriving
  // faster than the tick just move the target without rebuilding
  // SfRadialGauge, which previously saturated the UI thread.
  static const Duration _tickInterval = Duration(milliseconds: 66);
  // Per-tick EMA weights, 1 - e^(-tick/tau): tau 150ms rising, 1.5s falling.
  static const double _attackAlpha = 0.36;
  static const double _decayAlpha = 0.043;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.valueStream != null) {
      _setupStreamListener();
    }
  }

  void _setupStreamListener() {
    _streamSubscription?.cancel();
    _ticker?.cancel();
    _ticker = null;

    if (widget.valueStream != null) {
      try {
        _streamSubscription = widget.valueStream!.listen(_onValue);
      } catch (e) {
        debugPrint("Stream listening error: $e");
      }
    }
  }

  void _onValue(int value) {
    _targetValue = value.toDouble();
    _ticker ??= Timer.periodic(_tickInterval, (_) => _tick());
  }

  void _tick() {
    if (!mounted) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    final delta = _targetValue - _currentValue;
    if (delta.abs() < 0.5) {
      // Close enough: snap, and idle the ticker until the next sample.
      _ticker?.cancel();
      _ticker = null;
      if (_currentValue != _targetValue) {
        setState(() {
          _currentValue = _targetValue;
        });
      }
    } else {
      setState(() {
        _currentValue += delta * (delta > 0 ? _attackAlpha : _decayAlpha);
      });
    }
  }

  @override
  void didUpdateWidget(BLEGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueStream != widget.valueStream &&
        widget.valueStream != null) {
      _setupStreamListener();
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  // Ring geometry: the arc thickness must match between the axis line
  // (the sage-20 track) and the RangePointer (the active arc).
  static const double _gaugeSize = 170;
  static const double _arcThickness = 16;

  @override
  Widget build(BuildContext context) {
    // 270° ring from 225° (Syncfusion: 135 → 45), active arc coloured by
    // sound level vs threshold, remainder sage-20. A white thumb with a sage
    // ring marks the threshold position on the arc — same treatment as the
    // onboarding mock's threshold-track thumb.
    final arcColor = gaugeArcColor(_currentValue, widget.selectedValue);
    return Column(
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
                axisLineStyle: const AxisLineStyle(
                  thickness: _arcThickness,
                  color: ColorManager.inactiveGauge,
                  cornerStyle: CornerStyle.bothCurve,
                ),
                pointers: <GaugePointer>[
                  RangePointer(
                    value: _currentValue,
                    width: _arcThickness,
                    color: arcColor,
                    cornerStyle: CornerStyle.bothCurve,
                    enableAnimation: false,
                  ),
                  // Threshold thumb: sits on the arc at the set threshold so
                  // the boundary the alert fires at is visible at a glance.
                  MarkerPointer(
                    value: widget.selectedValue.clamp(0, 120).toDouble(),
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
                          _currentValue.toStringAsFixed(0),
                          style: ThemeManager.gaugeValue,
                        ),
                        const Text(
                          "dB",
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
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: ColorManager.slate,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Threshold · ${widget.selectedValue} dB",
          maxLines: 1,
          style: ThemeManager.meta,
        ),
      ],
    );
  }
}
