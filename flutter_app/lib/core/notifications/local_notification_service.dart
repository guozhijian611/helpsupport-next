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
  static const _businessChannelId = 'helpsupport_reminders';
  static const _businessChannelName = 'HelpSupport reminders';
  static const _businessChannelDescription =
      'Treatment plan and journal reminders for HelpSupport.';
  static const _androidSmallIcon = 'ic_stat_helpsupport_notification';
  static const journalReminderNotificationId = 210000001;
  static const _developerNotificationDelay = Duration(seconds: 3);
  static const _developerToolsChannel = MethodChannel(
    'helpsupport/developer_tools',
  );

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const NotificationDetails _developerNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          _developerChannelId,
          _developerChannelName,
          channelDescription: _developerChannelDescription,
          icon: _androidSmallIcon,
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

  static const NotificationDetails _businessNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          _businessChannelId,
          _businessChannelName,
          channelDescription: _businessChannelDescription,
          icon: _androidSmallIcon,
          importance: Importance.high,
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

  Future<void> initialize() async {
    await _configureLocalTimeZone();
    const androidSettings = AndroidInitializationSettings(_androidSmallIcon);
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

  Future<DeveloperNotificationDispatchResult> showDeveloperTestNotificationNow({
    required String title,
    required String body,
  }) async {
    final timeZoneIdentifier = await _configureLocalTimeZone();
    await _plugin.cancelAll();
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    final shownAt = DateTime.now();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _developerNotificationDetails,
      payload: 'developer-test-now:$id',
    );
    final pendingRequests = await _plugin.pendingNotificationRequests();
    final deliveredNotifications = await _plugin.getActiveNotifications();
    final diagnostics = await readDeveloperNotificationDiagnostics();
    return DeveloperNotificationDispatchResult(
      id: id,
      pendingCount: pendingRequests.length,
      deliveredCount: deliveredNotifications.length,
      scheduledAt: shownAt,
      timeZoneIdentifier: timeZoneIdentifier,
      diagnostics: diagnostics,
    );
  }

  Future<DeveloperNotificationDispatchResult>
  scheduleDeveloperTestNotification({
    required String title,
    required String body,
    Duration delay = _developerNotificationDelay,
  }) async {
    final timeZoneIdentifier = await _configureLocalTimeZone();
    final displayScheduledAt = DateTime.now().add(delay);
    await _plugin.cancelAll();
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    final scheduledAt = timezone.TZDateTime.now(timezone.local).add(delay);
    var androidScheduleMode = await _developerAndroidScheduleMode();
    var fellBackFromExactAlarm = false;
    try {
      await _scheduleDeveloperNotification(
        id: id,
        title: title,
        body: body,
        scheduledAt: scheduledAt,
        androidScheduleMode: androidScheduleMode,
      );
    } on PlatformException catch (error) {
      if (error.code != 'exact_alarms_not_permitted' ||
          androidScheduleMode == AndroidScheduleMode.inexactAllowWhileIdle) {
        rethrow;
      }
      androidScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      fellBackFromExactAlarm = true;
      await _scheduleDeveloperNotification(
        id: id,
        title: title,
        body: body,
        scheduledAt: scheduledAt,
        androidScheduleMode: androidScheduleMode,
      );
    }
    final pendingRequests = await _plugin.pendingNotificationRequests();
    final deliveredNotifications = await _plugin.getActiveNotifications();
    final diagnostics = await readDeveloperNotificationDiagnostics();
    return DeveloperNotificationDispatchResult(
      id: id,
      pendingCount: pendingRequests.length,
      deliveredCount: deliveredNotifications.length,
      scheduledAt: displayScheduledAt,
      timeZoneIdentifier: timeZoneIdentifier,
      diagnostics: <String, Object?>{
        ...?diagnostics,
        'androidScheduleMode': androidScheduleMode.name,
        'fellBackFromExactAlarm': fellBackFromExactAlarm,
      },
    );
  }

  Future<AndroidScheduleMode> _developerAndroidScheduleMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    try {
      var canScheduleExact = await android.canScheduleExactNotifications();
      if (canScheduleExact == false) {
        final requestResult = await android.requestExactAlarmsPermission();
        canScheduleExact =
            requestResult ?? await android.canScheduleExactNotifications();
      }
      return canScheduleExact == false
          ? AndroidScheduleMode.inexactAllowWhileIdle
          : AndroidScheduleMode.exactAllowWhileIdle;
    } on Object {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  Future<void> _scheduleDeveloperNotification({
    required int id,
    required String title,
    required String body,
    required timezone.TZDateTime scheduledAt,
    required AndroidScheduleMode androidScheduleMode,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledAt,
      notificationDetails: _developerNotificationDetails,
      androidScheduleMode: androidScheduleMode,
      payload: 'developer-test:$id',
    );
  }

  Future<void> cancelNotifications(Iterable<int> ids) async {
    for (final id in ids.toSet()) {
      await _plugin.cancel(id: id);
    }
  }

  Future<bool> scheduleTreatmentTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!scheduledDate.isAfter(DateTime.now())) {
      return false;
    }
    await _configureLocalTimeZone();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: timezone.TZDateTime.from(scheduledDate, timezone.local),
      notificationDetails: _businessNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
    return true;
  }

  Future<void> scheduleDailyJournalReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _configureLocalTimeZone();
    await _plugin.cancel(id: journalReminderNotificationId);
    final now = timezone.TZDateTime.now(timezone.local);
    var scheduledDate = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: journalReminderNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _businessNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'journal-reminder',
    );
  }

  Future<void> cancelDailyJournalReminder() {
    return _plugin.cancel(id: journalReminderNotificationId);
  }
}
