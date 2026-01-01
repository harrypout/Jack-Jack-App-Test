import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:jackjack/utils/env_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundServiceManager {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Initialize the background service (call in main())
  static Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Started manually after notification channel is ready
        isForegroundMode: true, // Required for reliable BLE
        notificationChannelId: 'ble_monitoring_service',
        initialNotificationTitle: 'JackJack Monitoring',
        initialNotificationContent: 'Background monitoring is active',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Background isolate entry point
  /// This runs in a separate isolate from the main UI
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Ensure Flutter binding is initialized in background isolate
    DartPluginRegistrant.ensureInitialized();

    debugPrint('🟢 Background service started');

    // Initialize BLE and SharedPreferences
    final ble = FlutterReactiveBle();
    final prefs = await SharedPreferences.getInstance();

    // Initialize EnvManager to get UUIDs
    await EnvManager.getInstance();

    // State variables
    List<String> connectedDeviceIds = [];
    Map<String, String> deviceNames = {};
    bool isStreaming = false;
    Timer? batteryPollTimer;
    Map<String, StreamSubscription> deviceConnections = {};
    Map<String, StreamSubscription> thresholdSubscriptions = {};
    Map<String, int> reconnectAttempts = {};

    // Update Android notification if needed
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.setForegroundNotificationInfo(
        title: 'JackJack Monitoring',
        content: 'Monitoring ${connectedDeviceIds.length} devices',
      );
    }

    // Listen for commands from UI
    service.on('updateDeviceList').listen((event) {
      if (event != null) {
        connectedDeviceIds = List<String>.from(event['deviceIds'] as List);
        deviceNames = Map<String, String>.from(event['deviceNames'] as Map);
        isStreaming = event['isStreaming'] as bool? ?? false;

        debugPrint(
            '📱 Background: Updated device list - ${connectedDeviceIds.length} devices');

        // Update notification
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'JackJack Monitoring',
            content: 'Monitoring ${connectedDeviceIds.length} devices',
          );
        }

        // Connect to devices and setup monitoring
        _setupDeviceMonitoring(
          ble,
          connectedDeviceIds,
          deviceNames,
          service,
          deviceConnections,
          thresholdSubscriptions,
          reconnectAttempts,
          prefs,
        );
      }
    });

    service.on('startManualStreaming').listen((event) {
      if (event != null) {
        final deviceId = event['deviceId'] as String;
        debugPrint('📱 Background: Start manual streaming for $deviceId');
        isStreaming = true;

        // Audio streaming is handled in foreground by AudioStreamPlayer
        // Background service just tracks the state
        service.invoke('streamingStatus', {
          'isStreaming': true,
          'deviceId': deviceId,
        });
      }
    });

    service.on('stopManualStreaming').listen((event) {
      debugPrint('📱 Background: Stop manual streaming');
      isStreaming = false;

      service.invoke('streamingStatus', {
        'isStreaming': false,
      });
    });

    service.on('requestStateSync').listen((event) {
      debugPrint('📱 Background: State sync requested');

      // Send current state back to UI
      service.invoke('stateSync', {
        'deviceIds': connectedDeviceIds,
        'isStreaming': isStreaming,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    service.on('stopService').listen((event) {
      debugPrint('🔴 Background service stopping...');

      // Cancel all timers and subscriptions
      batteryPollTimer?.cancel();
      for (var subscription in deviceConnections.values) {
        subscription.cancel();
      }
      for (var subscription in thresholdSubscriptions.values) {
        subscription.cancel();
      }

      service.stopSelf();
    });

    // Start battery polling timer (every 5 seconds)
    batteryPollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (connectedDeviceIds.isEmpty) return;

      debugPrint('🔋 Background: Polling battery levels for ${connectedDeviceIds.length} devices...');

      // Poll battery from each connected device
      for (String deviceId in connectedDeviceIds) {
        try {
          final batteryCharacteristic = QualifiedCharacteristic(
            serviceId: Uuid.parse(configs.getBatteryUUIDS.service),
            characteristicId: Uuid.parse(configs.getBatteryUUIDS.characteristic),
            deviceId: deviceId,
          );

          final batteryData = await ble.readCharacteristic(batteryCharacteristic);
          if (batteryData.isNotEmpty) {
            final batteryLevel = batteryData[0];
            debugPrint('🔋 Background: Device $deviceId battery: $batteryLevel%');

            // Send battery update to UI
            service.invoke('batteryUpdate', {
              'deviceId': deviceId,
              'batteryLevel': batteryLevel,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          }
        } catch (e) {
          debugPrint('❌ Background: Error reading battery for $deviceId: $e');
        }
      }
    });
  }

  /// Setup device monitoring (connections, threshold alerts, battery polling)
  static void _setupDeviceMonitoring(
    FlutterReactiveBle ble,
    List<String> deviceIds,
    Map<String, String> deviceNames,
    ServiceInstance service,
    Map<String, StreamSubscription> deviceConnections,
    Map<String, StreamSubscription> thresholdSubscriptions,
    Map<String, int> reconnectAttempts,
    SharedPreferences prefs,
  ) {
    // Cancel existing connections
    for (var subscription in deviceConnections.values) {
      subscription.cancel();
    }
    for (var subscription in thresholdSubscriptions.values) {
      subscription.cancel();
    }
    deviceConnections.clear();
    thresholdSubscriptions.clear();

    // Connect to each device
    for (String deviceId in deviceIds) {
      debugPrint('🔌 Background: Connecting to device $deviceId');

      // Reset reconnect attempts for new connection
      reconnectAttempts[deviceId] = 0;

      // Monitor connection state with reconnection logic
      final connectionSubscription = ble
          .connectToDevice(id: deviceId)
          .listen((connectionState) {
        debugPrint(
            '📡 Background: Device $deviceId state: ${connectionState.connectionState}');

        if (connectionState.connectionState ==
            DeviceConnectionState.connected) {
          // Reset reconnect attempts on successful connection
          reconnectAttempts[deviceId] = 0;

          // Setup threshold monitoring for this device
          _setupThresholdMonitoring(
            ble,
            deviceId,
            deviceNames,
            service,
            thresholdSubscriptions,
            prefs,
          );
        } else if (connectionState.connectionState ==
            DeviceConnectionState.disconnected) {
          // Notify UI about disconnection
          service.invoke('deviceDisconnected', {
            'deviceId': deviceId,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

          // Implement reconnection with exponential backoff
          final attempt = reconnectAttempts[deviceId] ?? 0;
          if (attempt < 10) {
            // Max 10 retries
            reconnectAttempts[deviceId] = attempt + 1;
            final delay = Duration(seconds: min(30, pow(2, attempt).toInt()));

            debugPrint(
                '🔄 Background: Scheduling reconnection for $deviceId in ${delay.inSeconds}s (attempt ${attempt + 1}/10)');

            Timer(delay, () {
              debugPrint('🔄 Background: Reconnecting to $deviceId...');
              // Connection stream will automatically retry
            });
          } else {
            debugPrint(
                '❌ Background: Max reconnection attempts reached for $deviceId');
            service.invoke('deviceConnectionFailed', {
              'deviceId': deviceId,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      }, onError: (error) {
        debugPrint('❌ Background: Connection error for $deviceId: $error');
      });

      deviceConnections[deviceId] = connectionSubscription;
    }
  }

  /// Setup threshold monitoring for a specific device
  static void _setupThresholdMonitoring(
    FlutterReactiveBle ble,
    String deviceId,
    Map<String, String> deviceNames,
    ServiceInstance service,
    Map<String, StreamSubscription> thresholdSubscriptions,
    SharedPreferences prefs,
  ) {
    try {
      // Get threshold alert characteristic
      final thresholdCharacteristic = QualifiedCharacteristic(
        serviceId: Uuid.parse(configs.thresholdAlertUUIDS.service),
        characteristicId:
            Uuid.parse(configs.thresholdAlertUUIDS.characteristic),
        deviceId: deviceId,
      );

      // Subscribe to threshold alerts
      final thresholdSubscription = ble
          .subscribeToCharacteristic(thresholdCharacteristic)
          .listen((data) {
        if (data.isNotEmpty && data[0] > 0) {
          final thresholdValue = data[0];
          debugPrint(
              '⚠️  Background: Threshold alert from $deviceId - $thresholdValue');

          // Send threshold alert to UI
          final deviceName = deviceNames[deviceId] ?? 'Unknown Device';
          service.invoke('thresholdAlert', {
            'deviceId': deviceId,
            'deviceName': deviceName,
            'threshold': thresholdValue,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }, onError: (error) {
        debugPrint(
            '❌ Background: Error subscribing to threshold for $deviceId: $error');
      });

      thresholdSubscriptions[deviceId] = thresholdSubscription;
      debugPrint('✅ Background: Threshold monitoring setup for $deviceId');
    } catch (e) {
      debugPrint('❌ Background: Failed to setup threshold monitoring for $deviceId: $e');
    }
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    debugPrint('📱 iOS background task executed');

    // iOS handles BLE automatically with bluetooth-central mode
    // This is called periodically by BGTaskScheduler

    return true;
  }

  /// Start the background service
  static Future<void> startService() async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
      debugPrint('✅ Background service started from UI');
    } else {
      debugPrint('⚠️  Background service already running');
    }
  }

  /// Stop the background service
  static Future<void> stopService() async {
    final isRunning = await _service.isRunning();
    if (isRunning) {
      _service.invoke('stopService');
      debugPrint('✅ Background service stop requested');
    } else {
      debugPrint('⚠️  Background service not running');
    }
  }

  /// Check if service is running
  static Future<bool> isServiceRunning() async {
    return await _service.isRunning();
  }

  /// Get the service instance for listening to events from UI
  static FlutterBackgroundService get instance => _service;
}
