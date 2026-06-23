import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._();
  static NotificationManager get instance => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Monotonic id so rapid/successive notifications don't overwrite each other.
  // DateTime.now().millisecond only spans 0-999 and collided frequently.
  int _notificationIdCounter = 0;

  NotificationManager._();

  /// Initializes the plugin only. Does NOT prompt for permission, so it can
  /// run during startup without blocking first frame on a system dialog.
  /// Call [requestPermission] after the UI is up.
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// Requests notification permission. Safe to call after first frame.
  Future<void> requestPermission() async {
    await Permission.notification.request();
  }

  AndroidNotificationDetails defaultNotificationDetails({
    bool enableVibration = false,
    playSound = false,
  }) => AndroidNotificationDetails(
    'threshold_alerts_channel${playSound ? "_sound" : ""}${enableVibration ? "_vibration" : ""}',
    'Threshold Alerts with ${playSound ? "Sound" : "No Sound"} and ${enableVibration ? "Vibration" : "No Vibration"}',
    channelDescription: 'Alerts when sound level exceeds threshold',
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: enableVibration,
    playSound: playSound,
  );

  AndroidNotificationDetails get noSoundNoVibrationNotificationDetails =>
      defaultNotificationDetails(enableVibration: false, playSound: false);

  AndroidNotificationDetails get soundNoVibrationNotificationDetails =>
      defaultNotificationDetails(enableVibration: false, playSound: true);

  AndroidNotificationDetails get noSoundVibrationNotificationDetails =>
      defaultNotificationDetails(enableVibration: true, playSound: false);

  AndroidNotificationDetails get soundVibrationNotificationDetails =>
      defaultNotificationDetails(enableVibration: true, playSound: true);

  AndroidNotificationDetails getNotificationDetails({
    required bool vibration,
    required bool sound,
  }) {
    if (vibration && sound) {
      return soundVibrationNotificationDetails;
    } else if (vibration && !sound) {
      return noSoundVibrationNotificationDetails;
    } else if (!vibration && sound) {
      return soundNoVibrationNotificationDetails;
    } else {
      return noSoundNoVibrationNotificationDetails;
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required bool vibration,
    required bool sound,
  }) async {
    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: sound,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: getNotificationDetails(vibration: vibration, sound: sound),
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      _notificationIdCounter++,
      title,
      body,
      platformDetails,
    );
  }

  Future<void> showThresholdAlert({
    required String deviceId,
    required String deviceName,
    required int threshold,
  }) async {
    final hasSound = prefs.getBool("${deviceId}s") ?? false;
    final hasVibration = prefs.getBool("${deviceId}v") ?? false;
    debugPrint(
      "Threshold Alert:: Sound: $hasSound, Vibration: $hasVibration, Device ID: $deviceId",
    );
    await showNotification(
      title: 'Sound Alert',
      body: 'Sound level exceeded on $deviceName',
      vibration: hasVibration,
      sound: hasSound,
    );
  }

    Future<void> showDisconnectionAlert({
    required String deviceId,
    required String deviceName,
  }) async {
    final hasSound = prefs.getBool("${deviceId}s") ?? false;
    final hasVibration = prefs.getBool("${deviceId}v") ?? false;
    debugPrint(
      "Disconnection Alert:: Sound: $hasSound, Vibration: $hasVibration, Device ID: $deviceId",
    );
    await showNotification(
      title: 'Device Alert',
      body: '$deviceName was disconnected',
      vibration: hasVibration,
      sound: hasSound,
    );
  }
}
