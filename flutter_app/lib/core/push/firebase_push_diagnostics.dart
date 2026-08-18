class FirebasePushEvent {
  const FirebasePushEvent({
    required this.receivedAt,
    required this.source,
    this.messageId,
    this.title,
    this.body,
    this.data = const <String, String>{},
  });

  final DateTime receivedAt;
  final String source;
  final String? messageId;
  final String? title;
  final String? body;
  final Map<String, String> data;

  bool get isDeveloperTest => data['developer_test'] == '1';

  Map<String, Object?> toJson() {
    return {
      'received_at': receivedAt.toIso8601String(),
      'source': source,
      'message_id': messageId,
      'title': title,
      'body': body,
      'data_keys': data.keys.toList(growable: false),
      'developer_test': isDeveloperTest,
    };
  }
}

class FirebasePushDiagnostics {
  const FirebasePushDiagnostics({
    required this.capturedAt,
    required this.available,
    required this.autoInitEnabled,
    required this.appsCount,
    this.initializeError,
    this.projectId = '',
    this.senderId = '',
    this.appId = '',
    this.iosBundleId = '',
    this.authorizationStatus = '',
    this.alertSetting = '',
    this.badgeSetting = '',
    this.soundSetting = '',
    this.lockScreenSetting = '',
    this.notificationCenterSetting = '',
    this.fcmToken,
    this.apnsToken,
    this.fcmTokenError,
    this.apnsTokenError,
    this.lastTokenRefresh,
    this.native = const <String, Object?>{},
    this.recentEvents = const <FirebasePushEvent>[],
  });

  final DateTime capturedAt;
  final bool available;
  final bool autoInitEnabled;
  final int appsCount;
  final String? initializeError;
  final String projectId;
  final String senderId;
  final String appId;
  final String iosBundleId;
  final String authorizationStatus;
  final String alertSetting;
  final String badgeSetting;
  final String soundSetting;
  final String lockScreenSetting;
  final String notificationCenterSetting;
  final String? fcmToken;
  final String? apnsToken;
  final String? fcmTokenError;
  final String? apnsTokenError;
  final DateTime? lastTokenRefresh;
  final Map<String, Object?> native;
  final List<FirebasePushEvent> recentEvents;

  bool get hasFcmToken => fcmToken != null && fcmToken!.isNotEmpty;
  bool get hasApnsToken => apnsToken != null && apnsToken!.isNotEmpty;

  String get nativePlatform => (native['platform'] as String?) ?? '';
  bool get isSimulator =>
      native['isSimulator'] == true || native['isEmulator'] == true;
  String get apsEnvironment => (native['apsEnvironment'] as String?) ?? '';
  bool get isRegisteredForRemoteNotifications =>
      native['isRegisteredForRemoteNotifications'] == true;
  bool get notificationsEnabled {
    final value = native['notificationsEnabled'];
    if (value is bool) {
      return value;
    }
    return authorizationStatus == 'authorized' ||
        authorizationStatus == 'provisional';
  }

  FirebasePushDiagnostics copyWith({
    List<FirebasePushEvent>? recentEvents,
    DateTime? lastTokenRefresh,
  }) {
    return FirebasePushDiagnostics(
      capturedAt: capturedAt,
      available: available,
      autoInitEnabled: autoInitEnabled,
      appsCount: appsCount,
      initializeError: initializeError,
      projectId: projectId,
      senderId: senderId,
      appId: appId,
      iosBundleId: iosBundleId,
      authorizationStatus: authorizationStatus,
      alertSetting: alertSetting,
      badgeSetting: badgeSetting,
      soundSetting: soundSetting,
      lockScreenSetting: lockScreenSetting,
      notificationCenterSetting: notificationCenterSetting,
      fcmToken: fcmToken,
      apnsToken: apnsToken,
      fcmTokenError: fcmTokenError,
      apnsTokenError: apnsTokenError,
      lastTokenRefresh: lastTokenRefresh ?? this.lastTokenRefresh,
      native: native,
      recentEvents: recentEvents ?? this.recentEvents,
    );
  }

  Map<String, Object?> toSafeJson() {
    return {
      'captured_at': capturedAt.toIso8601String(),
      'available': available,
      'auto_init_enabled': autoInitEnabled,
      'apps_count': appsCount,
      'initialize_error': initializeError,
      'project_id': projectId,
      'sender_id': senderId,
      'app_id': appId,
      'ios_bundle_id': iosBundleId,
      'authorization_status': authorizationStatus,
      'alert_setting': alertSetting,
      'badge_setting': badgeSetting,
      'sound_setting': soundSetting,
      'lock_screen_setting': lockScreenSetting,
      'notification_center_setting': notificationCenterSetting,
      'fcm_token_length': fcmToken?.length ?? 0,
      'apns_token_length': apnsToken?.length ?? 0,
      'fcm_token_error': fcmTokenError,
      'apns_token_error': apnsTokenError,
      'last_token_refresh': lastTokenRefresh?.toIso8601String(),
      'native': native,
      'recent_events': recentEvents
          .map((event) => event.toJson())
          .toList(growable: false),
    };
  }
}
