import 'dart:async';
import 'package:jackjack/utils/color_manager.dart';
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
  double gaugeRangeWidth = 10;

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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      width: 210,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            startAngle: 135,
            endAngle: 45,
            minimum: 0,
            maximum: 120.3,
            interval: 20,
            minorTicksPerInterval: 10,
            axisLabelStyle: GaugeTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: ColorManager.gaugeAxisLabelText,
            ),
            ranges: <GaugeRange>[
              GaugeRange(
                startValue: 0,
                endValue: _currentValue,
                color: ColorManager.inactiveGauge,
                gradient: SweepGradient(
                  colors: <Color>[
                    ColorManager.inactiveGauge,
                    ColorManager.accent,
                  ],
                  stops: <double>[0.25, 0.75],
                ),
                startWidth: gaugeRangeWidth,
                endWidth: gaugeRangeWidth,
              ),
              GaugeRange(
                startValue: _currentValue,
                endValue: 120.1,
                color: ColorManager.inactiveGauge,
                startWidth: gaugeRangeWidth,
                endWidth: gaugeRangeWidth,
              ),
            ],
            pointers: <GaugePointer>[
              NeedlePointer(
                value: _currentValue,
                needleColor: ColorManager.accent,
                needleLength: 0.5,
                needleStartWidth: 0,
                needleEndWidth: 5,
                knobStyle: const KnobStyle(
                  color: ColorManager.white,
                  borderColor: ColorManager.accent,
                  sizeUnit: GaugeSizeUnit.factor,
                  knobRadius: 0.05,
                ),
                tailStyle: const TailStyle(
                  width: 5,
                  lengthUnit: GaugeSizeUnit.factor,
                  length: 0.125,
                  color: ColorManager.accent,
                ),
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Text(
                  "${_currentValue.toStringAsFixed(0)} dB",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColorManager.secondaryText,
                  ),
                ),
                angle: 90,
                positionFactor: 0.65,
              ),
              GaugeAnnotation(
                widget: Text(
                  widget.selectedDevice,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorManager.tertiaryText,
                  ),
                ),
                angle: 90,
                positionFactor: 0.85,
              ),
              //todo: broken
              GaugeAnnotation(
                axisValue: widget.selectedValue.toDouble(),
                widget: Transform.rotate(
                  angle:
                      (135 +
                          ((widget.selectedValue <= 120
                                  ? widget.selectedValue
                                  : 120) *
                              2.25)) *
                      ((22 / 7) / 180),
                  child: Icon(Icons.arrow_back, color: ColorManager.success, size: 20),
                ),
                positionFactor: 1.09,
              ),
            ],
            majorTickStyle: MajorTickStyle(
              length: 10,
              thickness: 2,
              color: ColorManager.pill,
            ),
            minorTickStyle: MinorTickStyle(
              length: 6,
              thickness: 1,
              color: ColorManager.pill,
            ),
          ),
        ],
      ),
    );
  }
}
