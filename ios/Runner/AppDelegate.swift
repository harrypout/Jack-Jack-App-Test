import Flutter
import UIKit
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register background tasks
    if #available(iOS 13.0, *) {
      registerBackgroundTasks()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Background Task Registration

  @available(iOS 13.0, *)
  func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "com.jackjack.batteryPoll",
      using: nil
    ) { task in
      self.handleBatteryPollTask(task: task as! BGProcessingTask)
    }

    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "com.jackjack.bleMonitor",
      using: nil
    ) { task in
      self.handleBLEMonitorTask(task: task as! BGProcessingTask)
    }
  }

  // MARK: - Background Task Handlers

  @available(iOS 13.0, *)
  func handleBatteryPollTask(task: BGProcessingTask) {
    scheduleBackgroundTask(identifier: "com.jackjack.batteryPoll", interval: 5.0)

    let controller = window?.rootViewController as? FlutterViewController
    if let controller = controller {
      let channel = FlutterMethodChannel(
        name: "com.jackjack/background",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("executeBatteryPoll", arguments: nil)
    }

    task.setTaskCompleted(success: true)
  }

  @available(iOS 13.0, *)
  func handleBLEMonitorTask(task: BGProcessingTask) {
    scheduleBackgroundTask(identifier: "com.jackjack.bleMonitor", interval: 15.0)

    let controller = window?.rootViewController as? FlutterViewController
    if let controller = controller {
      let channel = FlutterMethodChannel(
        name: "com.jackjack/background",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("executeBLEMonitor", arguments: nil)
    }

    task.setTaskCompleted(success: true)
  }

  // MARK: - Background Task Scheduling

  @available(iOS 13.0, *)
  func scheduleBackgroundTask(identifier: String, interval: TimeInterval) {
    let request = BGProcessingTaskRequest(identifier: identifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
    request.requiresNetworkConnectivity = false
    request.requiresExternalPower = false

    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print("Could not schedule \(identifier): \(error)")
    }
  }
}
