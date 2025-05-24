import 'package:ble/screens/faq/widgets/faq_item.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:ble/widgets/ble_app_bar.dart';
import 'package:ble/widgets/ble_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FAQScreen extends StatelessWidget {
  static const String id = 'faq_screen';
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BLEBackground(
        child: SafeArea(
          child: Column(
            children: [
              BLEAppBar(title: "Help",
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ThemeManager.horizontalPadding),
                child: FAQItem(
                  question: "My device won’t connect, what should I do?",
                  answer: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.Rorem ipsum dolor sit amet, consectetur adipiscing elit. ",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
