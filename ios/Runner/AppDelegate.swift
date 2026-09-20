import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
    // BLE notifications wake the existing central using bluetooth-central.
    // BGProcessingTask is not a periodic or continuous monitoring guarantee.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
