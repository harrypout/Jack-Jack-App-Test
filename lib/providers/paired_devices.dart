// import '../main.dart';
//
// class PairedDevicesUUID {
//   static List<String> list = [];
//   static Future<void> loadFromPrefs() async {
//     list = prefs.getStringList('pairedDevicesUUID') ?? [];
//     print(list);
//   }
//
//   static Future<void> saveToPrefs(String uuid) async {
//     if (!list.contains(uuid)) {
//       print("Saving UUID: $uuid");
//       list.add(uuid);
//       await prefs.setStringList('pairedDevicesUUID', list);
//     }
//   }
// }
