import 'package:jackjack/models/faq.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
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
        borderRadius: ThemeManager.brLg,
      ),
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(width: 1, color: ColorManager.containerBorder),
        borderRadius: ThemeManager.brLg,
      ),
      childrenPadding: EdgeInsets.all(16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      expandedAlignment: Alignment.topLeft,
      children: [
        Text(
          faq.answer,
          // Body copy reads at slate-70; slate-60 is for captions/icons.
          style: const TextStyle(
            color: ColorManager.slate70,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
