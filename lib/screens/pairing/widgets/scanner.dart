import 'package:ble/screens/pairing/widgets/circles_animation_painter.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Scanner extends StatefulWidget {
  final String asset;
  final bool animate;

  const Scanner({super.key, required this.asset, this.animate = true});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _innerRadius;
  late Animation<double> _middleRadius;
  late Animation<double> _outerRadius;

  // Configuration values
  static const double _innerStart = 30;
  static const double _innerEnd = 50;
  static const double _middleStart = 50;
  static const double _middleEnd = 70;
  static const double _outerStart = 70;
  static const double _outerEnd = 90;
  static const Color _circleColor = ColorManager.accent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5; // Set to middle value for static display
    }

    _innerRadius = Tween<double>(
      begin: _innerStart,
      end: _innerEnd,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _middleRadius = Tween<double>(
      begin: _middleStart,
      end: _middleEnd,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _outerRadius = Tween<double>(
      begin: _outerStart,
      end: _outerEnd,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(Scanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation state if animate property changes
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.5;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: CirclesAnimationPainter(
                  innerRadius: _innerRadius.value,
                  middleRadius: _middleRadius.value,
                  outerRadius: _outerRadius.value,
                  color: _circleColor,
                ),
                size: Size.infinite,
              ),
              SvgPicture.asset(
                "assets/svgs/${widget.asset}.svg",
                width: 40,
                height: 40,
              ),
            ],
          );
        },
      ),
    );
  }
}
