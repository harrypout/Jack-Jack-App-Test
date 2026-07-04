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
  StreamSubscription<int>? _streamSubscription;

  // Throttle gauge repaints to ~15fps. The sound-level characteristic can
  // push values much faster, and rebuilding SfRadialGauge on every
  // notification saturates the UI thread.
  static const Duration _throttleInterval = Duration(milliseconds: 66);
  Timer? _throttleTimer;
  int? _pendingValue;

  @override
  void initState() {
    super.initState();
    if (widget.valueStream != null) {
      _setupStreamListener();
    }
  }

  void _setupStreamListener() {
    _streamSubscription?.cancel();
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _pendingValue = null;

    if (widget.valueStream != null) {
      try {
        _streamSubscription = widget.valueStream!.listen(_onValue);
      } catch (e) {
        debugPrint("Stream listening error: $e");
      }
    }
  }

  void _onValue(int value) {
    _pendingValue = value;
    // Leading edge: apply the first value immediately, then coalesce
    // subsequent values into at most one update per interval.
    if (_throttleTimer == null) {
      _flushPending();
      _throttleTimer = Timer.periodic(_throttleInterval, (_) {
        if (_pendingValue == null) {
          _throttleTimer?.cancel();
          _throttleTimer = null;
        } else {
          _flushPending();
        }
      });
    }
  }

  void _flushPending() {
    final value = _pendingValue;
    _pendingValue = null;
    if (value != null && mounted) {
      setState(() {
        _currentValue = value.toDouble();
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
    _throttleTimer?.cancel();
    super.dispose();
  }

  // Ring geometry: the arc thickness must match between the axis line
  // (the sage-20 track) and the RangePointer (the active arc).
  static const double _gaugeSize = 170;
  static const double _arcThickness = 16;

  @override
  Widget build(BuildContext context) {
    // 270° ring from 225° (Syncfusion: 135 → 45), active arc coloured by
    // sound level vs threshold, remainder sage-20. The threshold text below
    // replaces the old (broken) threshold-arrow annotation.
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
