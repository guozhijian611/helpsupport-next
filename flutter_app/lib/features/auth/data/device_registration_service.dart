import 'dart:ui';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/build_info.dart';
import '../../../core/push/firebase_push_service.dart';

class DeviceRegistrationService {
  const DeviceRegistrationService(
    this._apiClient,
    this._firebasePushService,
    this._preferences,
  );

  static const _deviceIdKey = 'helpsupport.device_id';

  final ApiClient _apiClient;
  final FirebasePushService _firebasePushService;
  final SharedPreferences _preferences;

  Future<void> registerCurrentDevice() async {
    final platform = _platformName();
    if (platform == null) {
      return;
    }

    final fcmToken = await _firebasePushService.readToken();
    final apnsToken = await _firebasePushService.readApnsToken();

    await _apiClient.postApi<Map<String, dynamic>>(
      '/app/help/push/device/register',
      data: {
        'device_id': await _deviceId(),
        'platform': platform,
        'fcm_token': fcmToken ?? '',
        'apns_token': apnsToken ?? '',
        'app_version': BuildInfo.appVersion,
        'locale': PlatformDispatcher.instance.locale.toLanguageTag(),
        'timezone': DateTime.now().timeZoneName,
      },
      decode: _map,
    );
  }

  Future<void> unregisterCurrentDevice() async {
    final platform = _platformName();
    final deviceId = _preferences.getString(_deviceIdKey);
    if (platform == null || deviceId == null || deviceId.isEmpty) {
      return;
    }

    await _apiClient.postApi<bool>(
      '/app/help/push/device/unregister',
      data: {'device_id': deviceId, 'platform': platform},
      decode: (_) => true,
    );
  }

  Future<String?> readCurrentDeviceId() async {
    final existing = _preferences.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    return _deviceId();
  }

  String? currentPlatform() => _platformName();

  Future<String> _deviceId() async {
    final existing = _preferences.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final value = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await _preferences.setString(_deviceIdKey, value);
    return value;
  }

  String? _platformName() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return const <String, dynamic>{};
  }
}
