import 'package:jackjack/screens/contact_us/contact_us_screen.dart';
import 'package:jackjack/screens/faq/faq_screen.dart';
import 'package:jackjack/screens/settings/widgets/settings_item.dart';
import 'package:jackjack/screens/settings/widgets/settings_section.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_app_bar.dart';
import 'package:jackjack/widgets/ble_background.dart';
import 'package:jackjack/widgets/ble_dropdown.dart';
import 'package:jackjack/widgets/ble_toggle.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

Map<String, Duration> notificationTimeoutOptions = {
  "15 seconds": Duration(seconds: 15),
  "30 seconds": Duration(seconds: 30),
  "1 minute": Duration(minutes: 1),
  "2 minutes": Duration(minutes: 2),
};
Duration get notificationTimeout {
  String key = prefs.getString("notificationTimeout") ?? "15 seconds";
  return notificationTimeoutOptions[key] ?? Duration(seconds: 15);
}

class SettingsScreen extends StatefulWidget {
  static const String id = 'settings_screen';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool autoConnect = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      autoConnect = prefs.getBool("autoConnect") ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BLEBackground(
        child: SafeArea(
          child: Column(
            children: [
              BLEAppBar(title: "Settings"),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ThemeManager.horizontalPadding,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SettingsSection(
                          section: "General",
                          divider: false,
                          children: [
                            SettingsItem(
                              assetName: "bluetooth",
                              title: "BLE Auto Connect",
                              trailing: BLEToggle(
                                value: autoConnect,
                                onChanged: (value) {
                                  setState(() {
                                    autoConnect = value;
                                  });
                                  prefs.setBool("autoConnect", value);
                                },
                              ),
                              onTap: () {
                                bool value = !autoConnect;
                                setState(() {
                                  autoConnect = value;
                                });
                                prefs.setBool("autoConnect", value);
                              },
                            ),
                            SettingsItem(
                              assetName: "help",
                              title: "Notification Timeout",
                              trailing: Container(
                                height: 50,
                                width: 150,
                                child: DropdownWithMap(
                                  hintText: "Select Timeout",
                                  items: notificationTimeoutOptions,
                                  initialSelection: notificationTimeout,
                                  onSelected: (Duration? duration) {
                                    if (duration != null) {
                                      String key = notificationTimeoutOptions
                                          .keys
                                          .firstWhere(
                                            (k) =>
                                                notificationTimeoutOptions[k] ==
                                                duration,
                                          );
                                      prefs.setString(
                                        "notificationTimeout",
                                        key,
                                      );
                                      setState(() {});
                                    }
                                  },
                                  width: 150,
                                ),
                              ),
                              onTap: () {},
                            ),
                          ],
                        ),
                        SettingsSection(
                          section: "Support",
                          children: [
                            SettingsItem(
                              assetName: "help",
                              title: "Help",
                              onTap: () {
                                Navigator.pushNamed(context, FAQScreen.id);
                              },
                            ),
                            SettingsItem(
                              assetName: "contact-us",
                              title: "Contact Us",
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  ContactUsScreen.id,
                                );
                              },
                            ),
                            SettingsItem(
                              assetName: "rate-app",
                              title: "Rate App",
                              onTap: () {},
                            ),
                          ],
                        ),
                        SettingsSection(
                          section: "About App",
                          children: [
                            SettingsItem(
                              assetName: "app-info",
                              title: "App Info",
                              onTap: () {},
                            ),
                            // SettingsItem(
                            //   assetName: "share",
                            //   title: "Share with Friends",
                            //   onTap: () {},
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
