import 'package:flutter/material.dart';
import '../main.dart';

class PairedDevicesUUID {
  static List<String> list = [];
  static List<String> get getList => list;
  static Future<void> loadFromPrefs() async {
    list = prefs.getStringList('pairedDevicesUUID') ?? [];
    debugPrint(list.toString());
  }

  static Future<void> saveToPrefs(String uuid) async {
    if (!list.contains(uuid)) {
      debugPrint("Saving UUID: $uuid");
      list.add(uuid);
      await prefs.setStringList('pairedDevicesUUID', list);
      await loadFromPrefs();
    }
  }

  static Future<void> removeFromPrefs(String uuid) async {
    if (list.contains(uuid)) {
      debugPrint("Removing UUID: $uuid");
      list.remove(uuid);
      await prefs.setStringList('pairedDevicesUUID', list);
      await loadFromPrefs();
    }
  }
}
