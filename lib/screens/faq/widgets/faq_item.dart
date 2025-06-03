import 'package:ble/models/faq.dart';
import 'package:ble/utils/color_manager.dart';
import 'package:flutter/material.dart';

class FAQItem extends StatelessWidget {
  final FAQ faq;
  const FAQItem({super.key, required this.faq});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      ),
      textColor: ColorManager.accent,
      collapsedTextColor: ColorManager.primaryText,
      backgroundColor: ColorManager.white,
      collapsedBackgroundColor: ColorManager.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(width: 1, color: ColorManager.containerBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(width: 1, color: ColorManager.containerBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      childrenPadding: EdgeInsets.all(16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      expandedAlignment: Alignment.topLeft,
      children: [
        Text(
          faq.answer,
          style: const TextStyle(
            color: ColorManager.tertiaryText,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
