import 'package:ble/utils/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class BLEGauge extends StatefulWidget {
  final String selectedDevice;
  const BLEGauge({super.key, required this.selectedDevice});

  @override
  State<BLEGauge> createState() => _BLEGaugeState();
}

class _BLEGaugeState extends State<BLEGauge> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int selectedValue = 90;
  double gaugeRangeWidth = 10;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 120).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      width: 210,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return SfRadialGauge(
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
                    endValue: _animation.value,
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
                    startValue: _animation.value,
                    endValue: 120.1,
                    color: ColorManager.inactiveGauge,
                    startWidth: gaugeRangeWidth,
                    endWidth: gaugeRangeWidth,
                  ),
                ],
                pointers: <GaugePointer>[
                  NeedlePointer(
                    value: _animation.value,
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
                      "${_animation.value.toStringAsFixed(0)} dB",
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
                    widget: Transform.rotate(
                      angle: (selectedValue / 120) * 2 * 3.141592653589793,
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    angle: (selectedValue / 120) * 360,
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
          );
        },
      ),
    );
  }
}