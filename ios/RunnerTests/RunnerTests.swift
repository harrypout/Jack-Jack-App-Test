import Flutter
import UserNotifications
import XCTest
import flutter_local_notifications

class RunnerTests: XCTestCase {
  func testNotificationInitializationWithoutPermissionPromptReturnsFalse() {
    // Exercise the real native plugin contract behind the Dart startup test.
    // On iOS false means no permission was requested, not failed plugin setup.
    let plugin = FlutterLocalNotificationsPlugin()
    let completed = expectation(description: "Notification plugin initialized")
    let settings: [String: Any] = [
      "requestAlertPermission": false,
      "requestBadgePermission": false,
      "requestSoundPermission": false,
      "requestProvisionalPermission": false,
      "requestCriticalPermission": false,
      "requestProvidesAppNotificationSettings": false,
      "notificationCategories": [],
    ]
    let call = FlutterMethodCall(methodName: "initialize", arguments: settings)
    plugin.handle(call) { result in
      XCTAssertEqual(result as? Bool, false)
      completed.fulfill()
    }
    wait(for: [completed], timeout: 10)
  }
}
