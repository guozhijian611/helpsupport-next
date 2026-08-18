import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'firebase_push_diagnostics.dart';

class FirebasePushService {
  FirebasePushService([this._messaging]);

  static const _apnsTokenWaitAttempts = 20;
  static const _apnsTokenWaitInterval = Duration(milliseconds: 250);
  static const _maxRecentEvents = 8;
  static const _developerToolsChannel = MethodChannel(
    'helpsupport/developer_tools',
  );

  FirebaseMessaging? _messaging;
  bool _available = false;
  bool _listenersBound = false;
  String? _initializeError;
  DateTime? _lastTokenRefresh;
  Future<void>? _initializeFuture;
  final List<FirebasePushEvent> _recentEvents = <FirebasePushEvent>[];
  final StreamController<List<FirebasePushEvent>> _eventsController =
      StreamController<List<FirebasePushEvent>>.broadcast();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool get isAvailable => _available;

  Stream<String> get tokenRefreshes {
    if (!_available) {
      return const Stream<String>.empty();
    }
    return _messaging?.onTokenRefresh ?? const Stream<String>.empty();
  }

  Stream<List<FirebasePushEvent>> get receivedEvents =>
      _eventsController.stream;

  List<FirebasePushEvent> get latestEvents =>
      List<FirebasePushEvent>.unmodifiable(_recentEvents);

  Future<void> initialize({bool force = false}) {
    if (force) {
      _initializeFuture = null;
    }
    return _initializeFuture ??= _doInitialize();
  }

  Future<NotificationSettings?> requestPermission() async {
    await initialize();
    if (!_available) {
      return null;
    }
    return _messaging?.requestPermission();
  }

  Future<String?> readToken() async {
    await initialize();
    if (!_available) {
      return null;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        await _waitForApnsToken() == null) {
      return null;
    }
    return _messaging?.getToken();
  }

  Future<String?> readApnsToken() async {
    await initialize();
    if (!_available) {
      return null;
    }
    return _waitForApnsToken();
  }

  Future<FirebasePushDiagnostics> readDiagnostics({
    bool waitForApns = false,
  }) async {
    await initialize();
    final native = await _readNativeDiagnostics();
    var authorizationStatus = '';
    var alertSetting = '';
    var badgeSetting = '';
    var soundSetting = '';
    var lockScreenSetting = '';
    var notificationCenterSetting = '';
    String? fcmToken;
    String? apnsToken;
    String? fcmTokenError;
    String? apnsTokenError;
    var projectId = '';
    var senderId = '';
    var appId = '';
    var iosBundleId = '';
    var autoInitEnabled = false;
    var appsCount = 0;

    try {
      appsCount = Firebase.apps.length;
      if (appsCount > 0) {
        final options = Firebase.app().options;
        projectId = options.projectId;
        senderId = options.messagingSenderId;
        appId = options.appId;
        iosBundleId = options.iosBundleId ?? '';
      }
    } on Object catch (error) {
      fcmTokenError ??= error.toString();
    }

    if (_available && _messaging != null) {
      autoInitEnabled = _messaging!.isAutoInitEnabled;
      try {
        final settings = await _messaging!.getNotificationSettings();
        authorizationStatus = _enumName(settings.authorizationStatus);
        alertSetting = _enumName(settings.alert);
        badgeSetting = _enumName(settings.badge);
        soundSetting = _enumName(settings.sound);
        lockScreenSetting = _enumName(settings.lockScreen);
        notificationCenterSetting = _enumName(settings.notificationCenter);
      } on Object catch (error) {
        fcmTokenError ??= error.toString();
      }

      try {
        apnsToken = waitForApns
            ? await _waitForApnsToken()
            : await _messaging!.getAPNSToken();
      } on Object catch (error) {
        apnsTokenError = error.toString();
      }

      try {
        if (defaultTargetPlatform == TargetPlatform.iOS &&
            (apnsToken == null || apnsToken.isEmpty)) {
          fcmTokenError ??= 'apns_token_unavailable';
        } else {
          fcmToken = await _messaging!.getToken();
        }
      } on Object catch (error) {
        fcmTokenError = error.toString();
      }
    }

    return FirebasePushDiagnostics(
      capturedAt: DateTime.now(),
      available: _available,
      autoInitEnabled: autoInitEnabled,
      appsCount: appsCount,
      initializeError: _initializeError,
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
      fcmToken: _nonEmpty(fcmToken),
      apnsToken: _nonEmpty(apnsToken),
      fcmTokenError: fcmTokenError,
      apnsTokenError: apnsTokenError,
      lastTokenRefresh: _lastTokenRefresh,
      native: native,
      recentEvents: latestEvents,
    );
  }

  Future<void> refreshToken() async {
    await initialize();
    if (!_available) {
      return;
    }
    await _messaging?.deleteToken();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _waitForApnsToken();
    }
    await _messaging?.getToken();
  }

  Future<void> _doInitialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _messaging ??= FirebaseMessaging.instance;
      await _messaging?.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _bindListeners();
      _available = true;
      _initializeError = null;
      unawaited(_captureInitialMessage());
    } on Object catch (error) {
      _available = false;
      _initializeError = error.toString();
    }
  }

  void _bindListeners() {
    if (_listenersBound || _messaging == null) {
      return;
    }
    _listenersBound = true;
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (message) => _recordEvent(message, 'foreground'),
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _recordEvent(message, 'opened'),
    );
    _tokenRefreshSubscription = _messaging!.onTokenRefresh.listen((_) {
      _lastTokenRefresh = DateTime.now();
    });
  }

  Future<void> _captureInitialMessage() async {
    try {
      final message = await _messaging?.getInitialMessage();
      if (message != null) {
        _recordEvent(message, 'initial');
      }
    } on Object {
      // Startup diagnostics should not break app launch.
    }
  }

  void _recordEvent(RemoteMessage message, String source) {
    final notification = message.notification;
    final event = FirebasePushEvent(
      receivedAt: DateTime.now(),
      source: source,
      messageId: _nonEmpty(message.messageId),
      title: _nonEmpty(notification?.title),
      body: _nonEmpty(notification?.body),
      data: Map<String, String>.from(message.data),
    );
    _recentEvents.insert(0, event);
    if (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeRange(_maxRecentEvents, _recentEvents.length);
    }
    _eventsController.add(latestEvents);
  }

  Future<Map<String, Object?>> _readNativeDiagnostics() async {
    try {
      final value = await _developerToolsChannel
          .invokeMapMethod<String, Object?>('getFirebasePushDiagnostics');
      return value ?? const <String, Object?>{};
    } on Object {
      return const <String, Object?>{};
    }
  }

  Future<String?> _waitForApnsToken() async {
    for (var attempt = 0; attempt < _apnsTokenWaitAttempts; attempt += 1) {
      final token = await _messaging?.getAPNSToken();
      if (token != null && token.isNotEmpty) {
        return token;
      }
      if (attempt + 1 < _apnsTokenWaitAttempts) {
        await Future<void>.delayed(_apnsTokenWaitInterval);
      }
    }
    return null;
  }

  String _enumName(Enum value) => value.name;

  String? _nonEmpty(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
