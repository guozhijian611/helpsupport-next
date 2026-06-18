import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let developerToolsChannelName = "helpsupport/developer_tools"
  private var developerToolsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    guard let registrar = self.registrar(forPlugin: developerToolsChannelName) else {
      return didFinish
    }
    let channel = FlutterMethodChannel(
      name: developerToolsChannelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleDeveloperToolsMethod(call: call, result: result)
    }
    developerToolsChannel = channel
    return didFinish
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func handleDeveloperToolsMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getTimeZone":
      result(TimeZone.current.identifier)
    case "getNotificationDiagnostics":
      readNotificationDiagnostics(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func readNotificationDiagnostics(result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      center.getPendingNotificationRequests { requests in
        center.getDeliveredNotifications { notifications in
          let formatter = ISO8601DateFormatter()
          formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

          let pendingRequests: [[String: Any]] = requests.map { request in
            var item: [String: Any] = [
              "identifier": request.identifier,
              "triggerType": "unknown"
            ]
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
              item["triggerType"] = "calendar"
              if let nextTriggerDate = trigger.nextTriggerDate() {
                item["nextTriggerDate"] = formatter.string(from: nextTriggerDate)
              }
            } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
              item["triggerType"] = "timeInterval"
              item["timeInterval"] = trigger.timeInterval
            }
            return item
          }

          result([
            "timeZoneIdentifier": TimeZone.current.identifier,
            "authorizationStatus": self.authorizationStatusText(settings.authorizationStatus),
            "alertSetting": self.notificationSettingText(settings.alertSetting),
            "soundSetting": self.notificationSettingText(settings.soundSetting),
            "badgeSetting": self.notificationSettingText(settings.badgeSetting),
            "lockScreenSetting": self.notificationSettingText(settings.lockScreenSetting),
            "notificationCenterSetting": self.notificationSettingText(settings.notificationCenterSetting),
            "carPlaySetting": self.notificationSettingText(settings.carPlaySetting),
            "alertStyle": self.alertStyleText(settings.alertStyle),
            "pendingCount": requests.count,
            "deliveredCount": notifications.count,
            "pendingRequests": pendingRequests,
            "providesAppNotificationSettings": settings.providesAppNotificationSettings
          ])
        }
      }
    }
  }

  private func authorizationStatusText(_ status: UNAuthorizationStatus) -> String {
    switch status {
    case .notDetermined:
      return "notDetermined"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    case .provisional:
      return "provisional"
    case .ephemeral:
      return "ephemeral"
    @unknown default:
      return "unknown"
    }
  }

  private func notificationSettingText(_ setting: UNNotificationSetting) -> String {
    switch setting {
    case .notSupported:
      return "notSupported"
    case .disabled:
      return "disabled"
    case .enabled:
      return "enabled"
    @unknown default:
      return "unknown"
    }
  }

  private func alertStyleText(_ style: UNAlertStyle) -> String {
    switch style {
    case .none:
      return "none"
    case .banner:
      return "banner"
    case .alert:
      return "alert"
    @unknown default:
      return "unknown"
    }
  }
}
