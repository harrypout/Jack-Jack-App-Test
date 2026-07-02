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

  bool _initialized = false;

  NotificationManager._();

  /// Initialize the notifications plugin (fast, no user interaction).
  Future<void> initializePlugin() async {
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
    _initialized = true;
  }

  /// Request notification permission from the OS (may show dialog).
  Future<void> requestPermission() async {
    await Permission.notification.request();
  }

  /// Full initialization (permission + plugin). Kept for backward compatibility.
  Future<void> initialize() async {
    await requestPermission();
    await initializePlugin();
  }

  AndroidNotificationDetails _buildAndroidDetails({
    required bool enableVibration,
    required bool playSound,
    String? soundName,
  }) {
    final soundSuffix = playSound ? '_${soundName ?? "default"}' : '';
    final vibrationSuffix = enableVibration ? '_vibration' : '';
    final channelId = 'alerts_channel${soundSuffix}$vibrationSuffix';
    final channelName =
        'Alerts with ${playSound ? (soundName ?? "Default") : "No Sound"}'
        ' and ${enableVibration ? "Vibration" : "No Vibration"}';

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Alerts when sound level exceeds threshold',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: enableVibration,
      playSound: playSound,
      sound:
          playSound && soundName != null
              ? RawResourceAndroidNotificationSound(soundName)
              : null,
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required bool vibration,
    required bool sound,
    String? soundName,
    String? soundFile,
  }) async {
    if (!_initialized) {
      debugPrint(
        '⚠️ NotificationManager: plugin not initialized yet, skipping notification',
      );
      return;
    }

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: sound,
      sound: sound && soundFile != null ? soundFile : null,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: _buildAndroidDetails(
        enableVibration: vibration,
        playSound: sound,
        soundName: soundName,
      ),
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
    );
  }

  // Maps display name to (filename_without_ext, extension)
  static const Map<String, (String, String)> _soundMap = {
    "Level Up": ("level_up", "mp3"),
    "Ping": ("ping", "mp3"),
    "Stomachache": ("stomachache_disconnected", "wav"),
    "Itemize": ("itemize", "wav"),
    "Missile Alert": ("missile_alert", "wav"),
  };

  /// Returns the filename without extension (for Android raw resources)
  String? _soundNameFromKey(String key) => _soundMap[key]?.$1;

  /// Returns the full filename with extension (for iOS)
  String? _soundFileFromKey(String key) {
    final entry = _soundMap[key];
    if (entry == null) return null;
    return '${entry.$1}.${entry.$2}';
  }

  Future<void> showThresholdAlert({
    required String deviceId,
    required String deviceName,
    required int threshold,
  }) async {
    final hasSound = prefs.getBool("${deviceId}s") ?? true;
    final hasVibration = prefs.getBool("${deviceId}v") ?? true;
    final soundKey = prefs.getString("thresholdSound") ?? "Default";
    final soundName = soundKey == "Default" ? null : _soundNameFromKey(soundKey);
    final soundFile = soundKey == "Default" ? null : _soundFileFromKey(soundKey);
    debugPrint(
      "Threshold Alert:: Sound: $hasSound, Vibration: $hasVibration, Device ID: $deviceId, SoundName: $soundName",
    );
    await showNotification(
      title: 'Sound Alert',
      body: 'Sound level exceeded on $deviceName',
      vibration: hasVibration,
      sound: hasSound,
      soundName: soundName,
      soundFile: soundFile,
    );
  }

  Future<void> showDisconnectionAlert({
    required String deviceId,
    required String deviceName,
  }) async {
    final hasSound = prefs.getBool("${deviceId}s") ?? true;
    final hasVibration = prefs.getBool("${deviceId}v") ?? true;
    final soundKey = prefs.getString("disconnectSound") ?? "Default";
    final soundName =
        soundKey == "Default" ? null : _soundNameFromKey(soundKey);
    final soundFile =
        soundKey == "Default" ? null : _soundFileFromKey(soundKey);
    debugPrint(
      "Disconnection Alert:: Sound: $hasSound, Vibration: $hasVibration, Device ID: $deviceId, SoundName: $soundName",
    );
    await showNotification(
      title: 'Device Alert',
      body: '$deviceName was disconnected',
      vibration: hasVibration,
      sound: hasSound,
      soundName: soundName,
      soundFile: soundFile,
    );
  }

  Future<void> showConnectionAlert({
    required String deviceId,
    required String deviceName,
  }) async {
    final hasSound = prefs.getBool("${deviceId}s") ?? true;
    final hasVibration = prefs.getBool("${deviceId}v") ?? true;
    final soundKey = prefs.getString("connectSound") ?? "Default";
    final soundName =
        soundKey == "Default" ? null : _soundNameFromKey(soundKey);
    final soundFile =
        soundKey == "Default" ? null : _soundFileFromKey(soundKey);
    debugPrint(
      "Connection Alert:: Sound: $hasSound, Vibration: $hasVibration, Device ID: $deviceId, SoundName: $soundName",
    );
    await showNotification(
      title: 'Device Alert',
      body: '$deviceName was connected',
      vibration: hasVibration,
      sound: hasSound,
      soundName: soundName,
      soundFile: soundFile,
    );
  }
}
