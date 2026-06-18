import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as timezone;

class DeveloperNotificationDispatchResult {
  const DeveloperNotificationDispatchResult({
    required this.id,
    required this.pendingCount,
    required this.deliveredCount,
    this.scheduledAt,
    this.timeZoneIdentifier,
    this.diagnostics,
  });

  final int id;
  final int pendingCount;
  final int deliveredCount;
  final DateTime? scheduledAt;
  final String? timeZoneIdentifier;
  final Map<String, Object?>? diagnostics;
}

class LocalNotificationService {
  static const _developerChannelId = 'helpsupport_developer_tools';
  static const _developerChannelName = 'Developer tools';
  static const _developerChannelDescription =
      'Developer self-test notifications for HelpSupport.';
  static const _developerNotificationDelay = Duration(seconds: 3);
  static const _developerToolsChannel = MethodChannel(
    'helpsupport/developer_tools',
  );

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize() async {
    await _configureLocalTimeZone();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);
  }

  Future<String?> _configureLocalTimeZone() async {
    try {
      final identifier = await _developerToolsChannel.invokeMethod<String>(
        'getTimeZone',
      );
      if (identifier == null || identifier.isEmpty) {
        return null;
      }
      timezone.setLocalLocation(timezone.getLocation(identifier));
      return identifier;
    } on Object {
      return null;
    }
  }

  Future<Map<String, Object?>?> readDeveloperNotificationDiagnostics() async {
    try {
      final map = await _developerToolsChannel.invokeMapMethod<String, Object?>(
        'getNotificationDiagnostics',
      );
      return map == null ? null : Map<String, Object?>.from(map);
    } on Object {
      return null;
    }
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

  Future<DeveloperNotificationDispatchResult>
  scheduleDeveloperTestNotification({
    required String title,
    required String body,
    Duration delay = _developerNotificationDelay,
  }) async {
    final timeZoneIdentifier = await _configureLocalTimeZone();
    final displayScheduledAt = DateTime.now().add(delay);
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

    await _plugin.cancelAll();
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    final scheduledAt = timezone.TZDateTime.now(timezone.local).add(delay);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledAt,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'developer-test:$id',
    );
    final pendingRequests = await _plugin.pendingNotificationRequests();
    final deliveredNotifications = await _plugin.getActiveNotifications();
    final diagnostics = await readDeveloperNotificationDiagnostics();
    return DeveloperNotificationDispatchResult(
      id: id,
      pendingCount: pendingRequests.length,
      deliveredCount: deliveredNotifications.length,
      scheduledAt: displayScheduledAt,
      timeZoneIdentifier: timeZoneIdentifier,
      diagnostics: diagnostics,
    );
  }
}
