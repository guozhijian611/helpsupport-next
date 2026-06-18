import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static const _developerChannelId = 'helpsupport_developer_tools';
  static const _developerChannelName = 'Developer tools';
  static const _developerChannelDescription =
      'Developer self-test notifications for HelpSupport.';

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);
  }

  Future<bool?> requestPermissions() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        await macos?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        await android?.requestNotificationsPermission();
  }

  Future<void> showDeveloperTestNotification({
    required String title,
    required String body,
  }) {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _developerChannelId,
        _developerChannelName,
        channelDescription: _developerChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentBadge: true,
        presentList: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentBadge: true,
        presentList: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      ),
    );

    return _plugin.show(
      id: 11009,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'developer-test',
    );
  }
}
