import 'package:jackjack/screens/contact_us/contact_us_screen.dart';
import 'package:jackjack/screens/faq/faq_screen.dart';
import 'package:jackjack/screens/settings/widgets/settings_item.dart';
import 'package:jackjack/screens/settings/widgets/settings_section.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:jackjack/widgets/ble_background.dart';
import 'package:jackjack/screens/settings/widgets/settings_selection.dart';
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

  Widget _soundSelection(String title, String preference, String selected) {
    return SettingsSelection<String>(
      assetName: 'sound',
      title: title,
      iconColor: ColorManager.yellowIcon,
      options: notificationSoundOptions,
      value: notificationSoundOptions[selected] ?? 'default',
      onSelected: (value) {
        if (value == null) return;
        final key = notificationSoundOptions.keys.firstWhere(
          (key) => notificationSoundOptions[key] == value,
          orElse: () => 'Default',
        );
        prefs.setString(preference, key);
        setState(() {});
      },
    );
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
                            SettingsSelection<Duration>(
                              assetName: 'help',
                              title: 'Notification Timeout',
                              iconColor: ColorManager.sage,
                              options: notificationTimeoutOptions,
                              value: notificationTimeout,
                              onSelected: (duration) {
                                if (duration == null) return;
                                final key = notificationTimeoutOptions.keys
                                    .firstWhere(
                                      (key) =>
                                          notificationTimeoutOptions[key] ==
                                          duration,
                                    );
                                prefs.setString('notificationTimeout', key);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        SettingsSection(
                          section: 'Notification Sounds',
                          accentDot: ColorManager.yellowDot,
                          children: [
                            _soundSelection(
                              'Connect Sound',
                              'connectSound',
                              connectSound,
                            ),
                            _soundSelection(
                              'Disconnect Sound',
                              'disconnectSound',
                              disconnectSound,
                            ),
                            _soundSelection(
                              'Threshold Sound',
                              'thresholdSound',
                              thresholdSound,
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
                              title: "TestFlight Feedback",
                              iconColor: ColorManager.coralIcon,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  ContactUsScreen.id,
                                );
                              },
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
                              onTap:
                                  () => showAboutDialog(
                                    context: context,
                                    applicationName: 'Jack Jack',
                                    children: [
                                      const Text(
                                        'Bluetooth sound monitoring for your Jack Jack. Sound levels and alert history stay on your phone. For this test release, use TestFlight to view build details and send feedback.',
                                      ),
                                    ],
                                  ),
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
