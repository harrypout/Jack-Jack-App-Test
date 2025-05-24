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
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

  Future<void> showNotification({
    required String title,
    required String body,
    required bool vibration,
    required bool sound,
  }) async {
    AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'threshold_alerts_channel',
          'Threshold Alerts',
          channelDescription: 'Alerts when sound level exceeds threshold',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: vibration,
          playSound: sound,
        );

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: sound,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
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
        "Sound: $hasSound, Vibration: $hasVibration, Device ID: $deviceId");
    await showNotification(
      title: 'Sound Alert',
      body: 'Sound level exceeded on $deviceName',
      vibration: hasVibration,
      sound: hasSound,
    );
  }
}
