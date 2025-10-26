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

  @override
  void initState() {
    super.initState();
    if (widget.valueStream != null) {
      _setupStreamListener();
    }
  }

  void _setupStreamListener() {
    _streamSubscription?.cancel();

    if (widget.valueStream != null) {
      try {
        _streamSubscription = widget.valueStream!.listen((value) {
          if (mounted) {
            setState(() {
              _currentValue = value.toDouble();
            });
          }
        });
      } catch (e) {
        debugPrint("Stream listening error: $e");
      }
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
                  child: Icon(Icons.arrow_back, color: Colors.green, size: 20),
                ),
                // angle: (selectedValue / 120) * 360,
                positionFactor: 0.8,
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
