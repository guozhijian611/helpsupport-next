import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebasePushService {
  FirebasePushService([this._messaging]);

  static const _apnsTokenWaitAttempts = 20;
  static const _apnsTokenWaitInterval = Duration(milliseconds: 250);

  FirebaseMessaging? _messaging;
  bool _available = false;

  bool get isAvailable => _available;

  Stream<String> get tokenRefreshes {
    if (!_available) {
      return const Stream<String>.empty();
    }
    return _messaging?.onTokenRefresh ?? const Stream<String>.empty();
  }

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _messaging ??= FirebaseMessaging.instance;
      await _messaging?.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _available = true;
    } on Object {
      _available = false;
    }
  }

  Future<NotificationSettings?> requestPermission() async {
    if (!_available) {
      return null;
    }
    return _messaging?.requestPermission();
  }

  Future<String?> readToken() async {
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
    if (!_available) {
      return null;
    }
    return _waitForApnsToken();
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
}
