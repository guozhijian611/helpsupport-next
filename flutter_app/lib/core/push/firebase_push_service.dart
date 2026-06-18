import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebasePushService {
  FirebasePushService([this._messaging]);

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
    return _messaging?.getToken();
  }

  Future<String?> readApnsToken() async {
    if (!_available) {
      return null;
    }
    return _messaging?.getAPNSToken();
  }
}
