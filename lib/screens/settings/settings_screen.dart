import 'package:ble/screens/faq/faq_screen.dart';
import 'package:ble/screens/settings/widgets/settings_item.dart';
import 'package:ble/screens/settings/widgets/settings_section.dart';
import 'package:ble/utils/theme_manager.dart';
import 'package:ble/widgets/ble_app_bar.dart';
import 'package:ble/widgets/ble_background.dart';
import 'package:ble/widgets/ble_toggle.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  static const String id = 'settings_screen';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BLEBackground(
        child: SafeArea(
          child: Column(
            children: [
              BLEAppBar(title: "Settings"),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ThemeManager.horizontalPadding,
                ),
                child: Column(
                  children: [
                    SettingsSection(
                      section: "General",
                      divider: false,
                      children: [
                        SettingsItem(
                          assetName: "bluetooth",
                          title: "BLE Auto Connect",
                          trailing: BLEToggle(value: true, onChanged: (value) {}),
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
                        Navigator.pushNamed(context, FAQScreen.id);},
                        ),
                        SettingsItem(
                          assetName: "contact-us",
                          title: "Contact Us",
                          onTap: () {},
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
                        SettingsItem(
                          assetName: "share",
                          title: "Share with Friends",
                          onTap: () {},
                        ),
                      ],
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
