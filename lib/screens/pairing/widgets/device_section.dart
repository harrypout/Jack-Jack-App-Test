import 'package:jackjack/utils/color_manager.dart';
import 'package:flutter/material.dart';

class DeviceSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const DeviceSection({
    super.key,
    required this.title,
    this.children = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if(children.isNotEmpty)
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: ColorManager.primaryText,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}
