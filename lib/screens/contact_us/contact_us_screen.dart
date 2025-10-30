import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/utils/toast_manager.dart';
import 'package:jackjack/widgets/ble_app_bar.dart';
import 'package:jackjack/widgets/ble_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jackjack/widgets/ble_filled_button.dart';
import 'package:jackjack/widgets/ble_text_form_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends ConsumerStatefulWidget {
  static const String id = 'contact_us_screen';
  const ContactUsScreen({super.key});

  @override
  ConsumerState createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  TextEditingController subjectController = TextEditingController();
  TextEditingController messageController = TextEditingController();

  Future<void> sendEmail({
    required String subject,
    required String message,
  }) async {
    String publisherEmail = 'your-email@example.com';
    final String encodedSubject = Uri.encodeComponent(subject);
    final String encodedMessage = Uri.encodeComponent(message);

    final String emailUrl =
        'mailto:$publisherEmail?subject=$encodedSubject&body=$encodedMessage';

    try {
      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
        Navigator.pop(context);
      } else {
        ToastManager.show("Failed to open email app");
      }
    } catch (e) {
      ToastManager.show("Failed to open email app");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BLEBackground(
        child: SafeArea(
          child: Column(
            children: [
              BLEAppBar(
                title: "Contact Us",
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
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: ThemeManager.horizontalPadding,
                            left: ThemeManager.horizontalPadding,
                            // bottom: MediaQuery.of(context).viewInsets.bottom + 5,
                          ),
                          child: Column(
                            children: [
                              BleTextFormFieldWithTitle(
                                controller: subjectController,
                                title: "Subject",
                                hintText: "Enter the subject of your message",
                                onChanged: (val) => setState(() {}),
                              ),
                              BleTextFormFieldWithTitle(
                                controller: messageController,
                                title: "Message",
                                hintText:
                                    "Please describe your issue or feedback in detail",
                                minLines: 5,
                                maxLines: 10,
                                onChanged: (val) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        right: ThemeManager.horizontalPadding,
                        left: ThemeManager.horizontalPadding,
                        bottom: 10,
                        // bottom: MediaQuery.of(context).viewInsets.bottom + 5,
                      ),
                      child: BLEFilledButton(
                        data: "Send",
                        maxButton: true,
                        buttonColor:
                            subjectController.text.isNotEmpty &&
                                    messageController.text.isNotEmpty
                                ? null
                                : ColorManager.accentDisabled,
                        onPressed:
                            subjectController.text.isNotEmpty &&
                                    messageController.text.isNotEmpty
                                ? () async => await sendEmail(
                                  subject: subjectController.text,
                                  message: messageController.text,
                                )
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
