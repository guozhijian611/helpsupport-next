import Flutter
import AVFoundation
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
    case "getFirebasePushDiagnostics":
      result(readFirebasePushDiagnostics())
    case "setCallSpeakerEnabled":
      setCallSpeakerEnabled(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func setCallSpeakerEnabled(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    let enabled = arguments?["enabled"] as? Bool ?? true
    let active = arguments?["active"] as? Bool ?? true
    let session = AVAudioSession.sharedInstance()
    do {
      if active {
        let options: AVAudioSession.CategoryOptions = enabled
          ? [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
          : [.allowBluetooth, .allowBluetoothA2DP]
        try session.setCategory(
          .playAndRecord,
          mode: .videoChat,
          options: options
        )
        try session.setActive(true)
      }
      if enabled {
        try session.overrideOutputAudioPort(.speaker)
      } else {
        try session.overrideOutputAudioPort(.none)
      }
      result(true)
    } catch {
      result(FlutterError(
        code: "CALL_SPEAKER_ROUTE_FAILED",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }

  private func readFirebasePushDiagnostics() -> [String: Any] {
    #if targetEnvironment(simulator)
    let isSimulator = true
    #else
    let isSimulator = false
    #endif
    let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
    return [
      "platform": "ios",
      "bundleId": Bundle.main.bundleIdentifier ?? "",
      "isSimulator": isSimulator,
      "apsEnvironment": readApsEnvironment(),
      "isRegisteredForRemoteNotifications": UIApplication.shared.isRegisteredForRemoteNotifications,
      "backgroundModes": backgroundModes,
      "hasRemoteNotificationBackgroundMode": backgroundModes.contains("remote-notification"),
    ]
  }

  private func readApsEnvironment() -> String {
    #if targetEnvironment(simulator)
    return "simulator"
    #else
    guard
      let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
      let data = try? Data(contentsOf: url),
      let raw = String(data: data, encoding: .isoLatin1)
    else {
      return "missing"
    }
    if let entitlements = provisionEntitlements(from: raw),
       let environment = entitlements["aps-environment"] as? String,
       !environment.isEmpty {
      return environment
    }
    return extractApsEnvironment(from: raw) ?? "missing"
    #endif
  }

  private func provisionEntitlements(from raw: String) -> [String: Any]? {
    guard let start = raw.range(of: "<?xml"),
          let end = raw.range(of: "</plist>") else {
      return nil
    }
    let xml = String(raw[start.lowerBound..<end.upperBound])
    guard let xmlData = xml.data(using: .utf8),
          let plist = try? PropertyListSerialization.propertyList(
            from: xmlData,
            options: [],
            format: nil
          ) as? [String: Any] else {
      return nil
    }
    return plist["Entitlements"] as? [String: Any]
  }

  private func extractApsEnvironment(from raw: String) -> String? {
    guard let keyRange = raw.range(of: "<key>aps-environment</key>") else {
      return nil
    }
    let remainder = raw[keyRange.upperBound...]
    guard let start = remainder.range(of: "<string>"),
          let end = remainder.range(of: "</string>") else {
      return nil
    }
    let value = remainder[start.upperBound..<end.lowerBound]
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? nil : value
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
