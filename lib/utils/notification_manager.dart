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

  NotificationManager._();

  Future<void> initialize() async {
    await Permission.notification.request();

    // Initialize notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(initializationSettings);
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
      DateTime.now().millisecond,
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
