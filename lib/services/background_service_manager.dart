import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:jackjack/utils/env_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
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
        initialNotificationTitle: 'JackJack',
        initialNotificationContent: 'Background monitoring active',
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
    Map<String, StreamSubscription> deviceConnections = {};
    Map<String, StreamSubscription> thresholdSubscriptions = {};
    Map<String, int> reconnectAttempts = {};

    // Background scanning state
    Set<String> disconnectedDeviceIds = {};
    StreamSubscription? scanSubscription;
    Timer? scanCycleTimer;
    bool isScanning = false;
    Map<String, DiscoveredDevice> discoveredDevices = {};

    // Background streaming state
    int streamingDuration = 0;
    Timer? streamingTimer;
    String? streamingDeviceId;

    // Helper function to stop background scanning
    void stopBackgroundScan() {
      debugPrint('🛑 Background: Stopping scan');
      scanSubscription?.cancel();
      scanCycleTimer?.cancel();
      isScanning = false;
      discoveredDevices.clear();
    }

    // Helper function to start background scanning
    void startBackgroundScan() {
      if (isScanning) {
        debugPrint('🔍 Background: Scan already running');
        return;
      }

      debugPrint('🔍 Background: Starting 35-second scan for ${disconnectedDeviceIds.length} disconnected devices');
      isScanning = true;
      discoveredDevices.clear();

      scanSubscription = ble
          .scanForDevices(
            withServices: [Uuid.parse(configs.setThresholdUUIDS.service)],
            scanMode: ScanMode.balanced,
          )
          .listen((device) {
        // Only process if this is a disconnected device we're looking for
        if (disconnectedDeviceIds.contains(device.id)) {
          debugPrint('🔍 Background: Found disconnected device: ${device.name} (${device.id})');

          if (discoveredDevices[device.id] == null) {
            discoveredDevices[device.id] = device;

            // Setup monitoring for reconnected device
            connectedDeviceIds.add(device.id);
            deviceNames[device.id] = device.name;

            _setupDeviceMonitoring(
              ble,
              [device.id],
              {device.id: device.name},
              service,
              deviceConnections,
              thresholdSubscriptions,
              reconnectAttempts,
              prefs,
              connectedDeviceIds,
              onDeviceDisconnected: (deviceId) {
                disconnectedDeviceIds.add(deviceId);
                if (!isScanning) {
                  startBackgroundScan();
                }
              },
              onDeviceReconnected: (deviceId) {
                disconnectedDeviceIds.remove(deviceId);
                if (disconnectedDeviceIds.isEmpty && isScanning) {
                  stopBackgroundScan();
                }
              },
            );

            // Remove from disconnected set
            disconnectedDeviceIds.remove(device.id);

            // Stop scanning if all devices reconnected
            if (disconnectedDeviceIds.isEmpty) {
              debugPrint('✅ Background: All devices reconnected, stopping scan');
              stopBackgroundScan();

              // Dismiss notification when all devices reconnected
              if (service is AndroidServiceInstance) {
                service.setAsBackgroundService();
              }
            }
          }
        }
      });

      // Stop scan after 35 seconds, wait 5 seconds, then restart if still needed
      scanCycleTimer?.cancel();
      scanCycleTimer = Timer(const Duration(seconds: 35), () async {
        debugPrint('🔍 Background: 35-second scan complete, pausing for 5 seconds');
        await scanSubscription?.cancel();
        isScanning = false;

        // Check if we still have disconnected devices
        if (disconnectedDeviceIds.isNotEmpty) {
          await Future.delayed(const Duration(seconds: 5));
          startBackgroundScan();
        } else {
          debugPrint('✅ Background: All devices reconnected during pause, scan stopped');
        }
      });
    }

    // Don't show notification initially - wait for device list update
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    // Listen for commands from UI
    service.on('updateDeviceList').listen((event) {
      if (event != null) {
        final allDeviceIds = List<String>.from(event['deviceIds'] as List);
        deviceNames = Map<String, String>.from(event['deviceNames'] as Map);
        isStreaming = event['isStreaming'] as bool? ?? false;
        final shouldScan = event['shouldScan'] as bool? ?? false;

        // Filter out devices that user manually disconnected
        connectedDeviceIds = allDeviceIds.where((deviceId) {
          final userDisconnected = prefs.getBool("user_disconnected_$deviceId") ?? false;
          if (userDisconnected) {
            debugPrint('📱 Background: Filtering out user-disconnected device: $deviceId');
          }
          return !userDisconnected;
        }).toList();

        debugPrint(
            '📱 Background: Updated device list - ${connectedDeviceIds.length} devices (${allDeviceIds.length - connectedDeviceIds.length} filtered)');

        // Update notification
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'JackJack',
            content: 'Background monitoring active',
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
          connectedDeviceIds,
          onDeviceDisconnected: (deviceId) {
            disconnectedDeviceIds.add(deviceId);
            if (!isScanning) {
              startBackgroundScan();
            }
          },
          onDeviceReconnected: (deviceId) {
            disconnectedDeviceIds.remove(deviceId);
            if (disconnectedDeviceIds.isEmpty && isScanning) {
              stopBackgroundScan();
            }
          },
        );

        // Start scanning if requested (when app goes to background with disconnected devices)
        if (shouldScan) {
          // Determine which devices are disconnected
          final allIds = allDeviceIds.toSet();
          final connectedIds = connectedDeviceIds.toSet();
          disconnectedDeviceIds = allIds.difference(connectedIds);

          if (disconnectedDeviceIds.isNotEmpty) {
            startBackgroundScan();
          }
        }
      }
    });

    service.on('stopBackgroundScan').listen((event) {
      debugPrint('📱 Background: Received stop scan command from foreground');
      stopBackgroundScan();
    });

    service.on('dismissNotification').listen((event) {
      debugPrint('📱 Background: Dismissing foreground notification');
      if (service is AndroidServiceInstance) {
        service.setAsBackgroundService();
      }
    });

    service.on('showNotification').listen((event) {
      debugPrint('📱 Background: Showing foreground notification');
      if (service is AndroidServiceInstance) {
        service.setAsForegroundService();
        service.setForegroundNotificationInfo(
          title: 'JackJack',
          content: 'Background monitoring active',
        );
      }
    });

    service.on('startManualStreaming').listen((event) {
      if (event != null) {
        streamingDeviceId = event['deviceId'] as String;
        streamingDuration = event['streamingDuration'] as int? ?? 0;

        debugPrint('🎵 Background: Taking over streaming timer (device: $streamingDeviceId, duration: ${streamingDuration}s)');
        isStreaming = true;

        // Start background timer
        streamingTimer?.cancel();
        streamingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          streamingDuration++;

          // Update notification every 30 seconds
          if (streamingDuration % 30 == 0 && service is AndroidServiceInstance) {
            final minutes = streamingDuration ~/ 60;
            final seconds = streamingDuration % 60;
            service.setForegroundNotificationInfo(
              title: 'JackJack',
              content: 'Audio streaming - ${minutes}m ${seconds}s',
            );
          }
        });

        // Update notification to show streaming status
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'JackJack',
            content: 'Audio streaming in background',
          );
        }

        service.invoke('streamingStatus', {
          'isStreaming': true,
          'deviceId': streamingDeviceId,
          'duration': streamingDuration,
        });
      }
    });

    service.on('stopManualStreaming').listen((event) {
      debugPrint('🎵 Background: Releasing streaming timer to foreground');
      isStreaming = false;
      streamingTimer?.cancel();
      streamingTimer = null;
      streamingDuration = 0;
      streamingDeviceId = null;

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
        'streamingDuration': streamingDuration,
        'streamingDeviceId': streamingDeviceId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    service.on('stopService').listen((event) {
      debugPrint('🔴 Background service stopping...');

      // Cancel all timers and subscriptions
      streamingTimer?.cancel();
      stopBackgroundScan();
      for (var subscription in deviceConnections.values) {
        subscription.cancel();
      }
      for (var subscription in thresholdSubscriptions.values) {
        subscription.cancel();
      }

      service.stopSelf();
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
    List<String> connectedDeviceIds, {
    Function(String)? onDeviceDisconnected,
    Function(String)? onDeviceReconnected,
  }) {
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

          // Handle reconnection callback
          onDeviceReconnected?.call(deviceId);

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

          // Check if user manually disconnected this device
          final userDisconnected = prefs.getBool("user_disconnected_$deviceId") ?? false;

          if (userDisconnected) {
            debugPrint('⏭️  Background: Skipping reconnection for $deviceId - user manually disconnected');
            // Remove from connected list since user doesn't want it connected
            connectedDeviceIds.remove(deviceId);
          } else {
            // Handle unintentional disconnect callback
            onDeviceDisconnected?.call(deviceId);

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
