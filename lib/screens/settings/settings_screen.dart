import 'package:jackjack/screens/contact_us/contact_us_screen.dart';
import 'package:jackjack/screens/faq/faq_screen.dart';
import 'package:jackjack/screens/settings/widgets/settings_item.dart';
import 'package:jackjack/screens/settings/widgets/settings_section.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_background.dart';
import 'package:jackjack/widgets/ble_dropdown.dart';
import 'package:jackjack/widgets/ble_toggle.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

Map<String, String> notificationSoundOptions = {
  "Default": "default",
  "Level Up": "level_up",
  "Ping": "ping",
  "Stomachache": "stomachache_disconnected",
  "Itemize": "itemize",
  "Missile Alert": "missile_alert",
};
String get connectSound => prefs.getString("connectSound") ?? "Default";
String get disconnectSound => prefs.getString("disconnectSound") ?? "Default";
String get thresholdSound => prefs.getString("thresholdSound") ?? "Default";

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
  bool autoConnect = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      autoConnect = prefs.getBool("autoConnect") ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BLEBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ThemeManager.horizontalPadding,
                  vertical: 8,
                ),
                child: Text("Settings", style: ThemeManager.displayTitle),
              ),
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
                          accentDot: ColorManager.sage,
                          children: [
                            SettingsItem(
                              assetName: "bluetooth",
                              title: "BLE Auto Connect",
                              iconColor: ColorManager.sage,
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
                              iconColor: ColorManager.sage,
                              trailing: Container(
                                height: 50,
                                // width: 150,
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
                                  width: 125,
                                ),
                              ),
                              onTap: () {},
                            ),
                          ],
                        ),
                        SettingsSection(
                          section: "Notification Sounds",
                          accentDot: ColorManager.yellowDot,
                          children: [
                            SettingsItem(
                              assetName: "sound",
                              title: "Connect Sound",
                              iconColor: ColorManager.yellowIcon,
                              trailing: Container(
                                height: 50,
                                child: DropdownWithMap(
                                  hintText: "Select Sound",
                                  items: notificationSoundOptions,
                                  initialSelection:
                                      notificationSoundOptions[connectSound],
                                  onSelected: (String? value) {
                                    String key = notificationSoundOptions.keys
                                        .firstWhere(
                                          (k) =>
                                              notificationSoundOptions[k] ==
                                              value,
                                          orElse: () => "Default",
                                        );
                                    prefs.setString("connectSound", key);
                                    setState(() {});
                                  },
                                  width: 125,
                                ),
                              ),
                              onTap: () {},
                            ),
                            SettingsItem(
                              assetName: "sound",
                              title: "Disconnect Sound",
                              iconColor: ColorManager.yellowIcon,
                              trailing: Container(
                                height: 50,
                                child: DropdownWithMap(
                                  hintText: "Select Sound",
                                  items: notificationSoundOptions,
                                  initialSelection:
                                      notificationSoundOptions[disconnectSound],
                                  onSelected: (String? value) {
                                    String key = notificationSoundOptions.keys
                                        .firstWhere(
                                          (k) =>
                                              notificationSoundOptions[k] ==
                                              value,
                                          orElse: () => "Default",
                                        );
                                    prefs.setString("disconnectSound", key);
                                    setState(() {});
                                  },
                                  width: 125,
                                ),
                              ),
                              onTap: () {},
                            ),
                            SettingsItem(
                              assetName: "sound",
                              title: "Threshold Sound",
                              iconColor: ColorManager.yellowIcon,
                              trailing: Container(
                                height: 50,
                                child: DropdownWithMap(
                                  hintText: "Select Sound",
                                  items: notificationSoundOptions,
                                  initialSelection:
                                      notificationSoundOptions[thresholdSound],
                                  onSelected: (String? value) {
                                    String key = notificationSoundOptions.keys
                                        .firstWhere(
                                          (k) =>
                                              notificationSoundOptions[k] ==
                                              value,
                                          orElse: () => "Default",
                                        );
                                    prefs.setString("thresholdSound", key);
                                    setState(() {});
                                  },
                                  width: 125,
                                ),
                              ),
                              onTap: () {},
                            ),
                          ],
                        ),
                        SettingsSection(
                          section: "Support",
                          accentDot: ColorManager.coralDot,
                          children: [
                            SettingsItem(
                              assetName: "help",
                              title: "Help",
                              iconColor: ColorManager.coralIcon,
                              onTap: () {
                                Navigator.pushNamed(context, FAQScreen.id);
                              },
                            ),
                            SettingsItem(
                              assetName: "contact-us",
                              title: "Contact Us",
                              iconColor: ColorManager.coralIcon,
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
                              iconColor: ColorManager.coralIcon,
                              onTap: () {},
                            ),
                          ],
                        ),
                        SettingsSection(
                          section: "About App",
                          accentDot: ColorManager.sage,
                          children: [
                            SettingsItem(
                              assetName: "app-info",
                              title: "App Info",
                              iconColor: ColorManager.sage,
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
