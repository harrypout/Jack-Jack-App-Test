import 'package:jackjack/widgets/ble_eyebrow.dart';
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [if (children.isNotEmpty) BLEEyebrow(title)],
          ),
        ),
        ...children,
      ],
    );
  }
}
