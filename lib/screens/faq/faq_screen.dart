import 'package:jackjack/screens/faq/faqs.dart';
import 'package:jackjack/screens/faq/widgets/faq_item.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_app_bar.dart';
import 'package:jackjack/widgets/ble_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FAQScreen extends StatelessWidget {
  static const String id = 'faq_screen';
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BLEBackground(
        child: Column(
          children: [
            SafeArea(
              child: BLEAppBar(
                title: "Help",
                leading: SvgPicture.asset(
                  "assets/svgs/arrow-left.svg",
                  width: 24,
                  height: 24,
                  fit: BoxFit.scaleDown,
                ),
                onLeadingTap: () {
                  Navigator.pop(context);
                },

              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: faqs.length,
                physics: const AlwaysScrollableScrollPhysics(),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                padding: EdgeInsets.symmetric(
                  horizontal: ThemeManager.horizontalPadding,
                ),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: 8,
                      top: index == 0 ? 8 : 0,
                    ),
                    child: FAQItem(
                      key: ObjectKey(faqs[index]),
                      faq: faqs[index],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
