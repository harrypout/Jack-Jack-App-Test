import 'package:ble/utils/color_manager.dart';
import 'package:flutter/material.dart';

class FAQItem extends StatelessWidget {
  final String question;
  final String answer;
  const FAQItem({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border.all(width: 1, color: ColorManager.containerBorder),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            // color: ColorManager.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        textColor: ColorManager.accent,
        collapsedTextColor: ColorManager.primaryText,
        backgroundColor: ColorManager.transparent,
        collapsedBackgroundColor: ColorManager.transparent,
        shape: RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: null,
        childrenPadding: EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            answer,
            style: const TextStyle(
              color: ColorManager.tertiaryText,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}