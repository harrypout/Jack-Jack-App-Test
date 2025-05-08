import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static Future<bool> check() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }
    }

    List<Permission> permissions = [Permission.location];

    if (Platform.isAndroid &&
        (int.tryParse(Platform.version.split('.')[0]) ?? 0) >= 12) {
      permissions.add(Permission.bluetoothScan);
      permissions.add(Permission.bluetoothConnect);
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      await openAppSettings();
    }

    return allGranted;
  }
}

//import 'dart:io';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class PermissionManager {
//   static Future<Position> checkPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (!serviceEnabled) {}
//
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         await Geolocator.openAppSettings();
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       throw "language lbl Location Permission Denied Permanently, please enable it from setting";
//     }
//
//     return await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high,
//         )
//         .then((value) {
//           return value;
//         })
//         .catchError((e) async {
//           return await Geolocator.getLastKnownPosition()
//               .then((value) async {
//                 if (value != null) {
//                   return value;
//                 } else {
//                   throw "lbl Enable Location";
//                 }
//               })
//               .catchError((e) {
//                 print(e.toString());
//               });
//         });
//   }
//
//   static Future<bool> requestLocationAndNearbyDevicesPermissions() async {
//     if (Platform.isAndroid) {
//       // Request location permission
//       PermissionStatus locationStatus = await Permission.location.request();
//
//       // For Android 12+ we need BLUETOOTH_SCAN and BLUETOOTH_CONNECT permissions
//       // which are used to discover and interact with nearby Bluetooth devices
//       bool hasPermissions = locationStatus.isGranted;
//
//       // Check Android version for nearby devices permissions (Bluetooth specific)
//       if ((int.tryParse(Platform.version.split('.')[0]) ?? 0) >= 12) {
//         Map<Permission, PermissionStatus> bluetoothStatuses =
//             await [
//               Permission.bluetoothScan,
//               Permission.bluetoothConnect,
//             ].request();
//
//         hasPermissions =
//             hasPermissions &&
//             bluetoothStatuses[Permission.bluetoothScan]!.isGranted &&
//             bluetoothStatuses[Permission.bluetoothConnect]!.isGranted;
//       }
//
//       return hasPermissions;
//     } else if (Platform.isIOS) {
//       // iOS handles Bluetooth permissions through system dialogs
//       return true;
//     }
//     return false;
//   }
// }
