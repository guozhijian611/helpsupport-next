class MeProfileBundle {
  const MeProfileBundle({
    required this.member,
    required this.profile,
    required this.doctorProfile,
    required this.currentRole,
    required this.roleFlags,
  });

  final Map<String, dynamic> member;
  final Map<String, dynamic> profile;
  final Map<String, dynamic> doctorProfile;
  final String currentRole;
  final Map<String, dynamic> roleFlags;

  factory MeProfileBundle.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected me profile shape');
    }

    return MeProfileBundle(
      member: _map(value['member']),
      profile: _map(value['profile']),
      doctorProfile: _map(value['doctor_profile']),
      currentRole: (value['current_role'] ?? '').toString().trim(),
      roleFlags: _map(value['role_flags']),
    );
  }

  String get nickname =>
      _firstText([member['nickname'], profile['nickname'], member['username']]);

  String get avatarUrl => _firstText([member['avatar']]);

  String get email => _firstText([member['email']]);

  String get mobile => _firstText([member['mobile']]);

  int? get gender {
    final value = profile['gender'];
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse((value ?? '').toString());
  }

  String get birthday => _firstText([profile['birthday']]);

  bool get isDoctor => currentRole == 'doctor';

  String get recoveryGoal => _firstText([profile['recovery_goal']]);

  String get bio => _firstText([profile['bio']]);

  String get profileBackground => _firstText([profile['profile_background']]);

  List<String> get triggerTags {
    final value = profile['trigger_tags'];
    if (value is List) {
      return value
          .map((item) => (item ?? '').toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      final normalized = value.trim();
      if (normalized.startsWith('[') && normalized.endsWith(']')) {
        final inner = normalized.substring(1, normalized.length - 1);
        return inner
            .split(',')
            .map((item) => item.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  static String _firstText(List<Object?> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty && text != 'null') {
        return text;
      }
    }
    return '';
  }
}

class SecurityOverview {
  const SecurityOverview({
    required this.member,
    required this.linkedAccounts,
    required this.devices,
    required this.recentLogins,
    required this.ssoEnabled,
    required this.activeDeviceCount,
  });

  final SecurityMember member;
  final List<SecurityLinkedAccount> linkedAccounts;
  final List<SecurityDevice> devices;
  final List<SecurityLoginLog> recentLogins;
  final bool ssoEnabled;
  final int activeDeviceCount;

  factory SecurityOverview.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected me security shape');
    }

    return SecurityOverview(
      member: SecurityMember.fromJson(value['member']),
      linkedAccounts: _list(
        value['linked_accounts'],
        SecurityLinkedAccount.fromJson,
      ),
      devices: _list(value['devices'], SecurityDevice.fromJson),
      recentLogins: _list(value['recent_logins'], SecurityLoginLog.fromJson),
      ssoEnabled: value['sso_enabled'] == true,
      activeDeviceCount: _intValue(value['active_device_count']),
    );
  }

  List<SecurityLinkedAccount> get thirdPartyAccounts =>
      linkedAccounts.where((item) {
        final code = item.platformCode.toUpperCase();
        return code == 'GOOGLE' || code == 'APPLE';
      }).toList();

  List<SecurityDevice> get activeDevices =>
      devices.where((item) => item.isActive).toList();

  static List<T> _list<T>(Object? value, T Function(Object? value) decode) {
    if (value is! List) {
      return const [];
    }
    return value.map<T>(decode).toList();
  }

  static int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}

class PushPreferenceSettings {
  const PushPreferenceSettings({
    required this.memberId,
    required this.isPushEnabled,
    required this.isTaskReminderEnabled,
    required this.isCommunityEnabled,
    required this.isAppointmentEnabled,
    required this.isAuditNoticeEnabled,
    required this.isLocalCompanionEnabled,
    required this.quietStartTime,
    required this.quietEndTime,
  });

  final int memberId;
  final bool isPushEnabled;
  final bool isTaskReminderEnabled;
  final bool isCommunityEnabled;
  final bool isAppointmentEnabled;
  final bool isAuditNoticeEnabled;
  final bool isLocalCompanionEnabled;
  final String quietStartTime;
  final String quietEndTime;

  factory PushPreferenceSettings.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const PushPreferenceSettings(
        memberId: 0,
        isPushEnabled: true,
        isTaskReminderEnabled: true,
        isCommunityEnabled: true,
        isAppointmentEnabled: true,
        isAuditNoticeEnabled: true,
        isLocalCompanionEnabled: true,
        quietStartTime: '',
        quietEndTime: '',
      );
    }

    return PushPreferenceSettings(
      memberId: SecurityOverview._intValue(value['member_id']),
      isPushEnabled: _enabledFlag(value['is_push_enabled'], fallback: true),
      isTaskReminderEnabled: _enabledFlag(
        value['is_task_reminder_enabled'],
        fallback: true,
      ),
      isCommunityEnabled: _enabledFlag(
        value['is_community_enabled'],
        fallback: true,
      ),
      isAppointmentEnabled: _enabledFlag(
        value['is_appointment_enabled'],
        fallback: true,
      ),
      isAuditNoticeEnabled: _enabledFlag(
        value['is_audit_notice_enabled'],
        fallback: true,
      ),
      isLocalCompanionEnabled: _enabledFlag(
        value['is_local_companion_enabled'],
        fallback: true,
      ),
      quietStartTime: (value['quiet_start_time'] ?? '').toString().trim(),
      quietEndTime: (value['quiet_end_time'] ?? '').toString().trim(),
    );
  }

  bool get hasAnyEnabled =>
      isTaskReminderEnabled ||
      isCommunityEnabled ||
      isAppointmentEnabled ||
      isAuditNoticeEnabled ||
      isLocalCompanionEnabled;

  static bool _enabledFlag(Object? value, {required bool fallback}) {
    if (value == null) {
      return fallback;
    }
    final normalized = SecurityOverview._intValue(value);
    if (normalized == 1) {
      return true;
    }
    if (normalized == 2) {
      return false;
    }
    return fallback;
  }
}

class SecurityMember {
  const SecurityMember({
    required this.id,
    required this.email,
    required this.mobile,
    required this.hasPassword,
  });

  final int id;
  final String email;
  final String mobile;
  final bool hasPassword;

  factory SecurityMember.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const SecurityMember(
        id: 0,
        email: '',
        mobile: '',
        hasPassword: false,
      );
    }

    return SecurityMember(
      id: SecurityOverview._intValue(value['id']),
      email: (value['email'] ?? '').toString().trim(),
      mobile: (value['mobile'] ?? '').toString().trim(),
      hasPassword: value['has_password'] == true,
    );
  }
}

class SecurityLinkedAccount {
  const SecurityLinkedAccount({
    required this.platformCode,
    required this.platformName,
    required this.platformOpenId,
    required this.bindTime,
  });

  final String platformCode;
  final String platformName;
  final String platformOpenId;
  final String bindTime;

  factory SecurityLinkedAccount.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const SecurityLinkedAccount(
        platformCode: '',
        platformName: '',
        platformOpenId: '',
        bindTime: '',
      );
    }

    return SecurityLinkedAccount(
      platformCode: (value['platform_code'] ?? '').toString().trim(),
      platformName: (value['platform_name'] ?? '').toString().trim(),
      platformOpenId: (value['platform_openid'] ?? '').toString().trim(),
      bindTime: (value['bind_time'] ?? '').toString().trim(),
    );
  }
}

class SecurityDevice {
  const SecurityDevice({
    required this.id,
    required this.deviceId,
    required this.platform,
    required this.appVersion,
    required this.locale,
    required this.timezone,
    required this.isActive,
    required this.lastActiveTime,
    required this.logoutTime,
  });

  final int id;
  final String deviceId;
  final String platform;
  final String appVersion;
  final String locale;
  final String timezone;
  final bool isActive;
  final String lastActiveTime;
  final String logoutTime;

  factory SecurityDevice.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const SecurityDevice(
        id: 0,
        deviceId: '',
        platform: '',
        appVersion: '',
        locale: '',
        timezone: '',
        isActive: false,
        lastActiveTime: '',
        logoutTime: '',
      );
    }

    return SecurityDevice(
      id: SecurityOverview._intValue(value['id']),
      deviceId: (value['device_id'] ?? '').toString().trim(),
      platform: (value['platform'] ?? '').toString().trim(),
      appVersion: (value['app_version'] ?? '').toString().trim(),
      locale: (value['locale'] ?? '').toString().trim(),
      timezone: (value['timezone'] ?? '').toString().trim(),
      isActive: SecurityOverview._intValue(value['is_active']) == 1,
      lastActiveTime: (value['last_active_time'] ?? '').toString().trim(),
      logoutTime: (value['logout_time'] ?? '').toString().trim(),
    );
  }
}

class SecurityLoginLog {
  const SecurityLoginLog({
    required this.platformCode,
    required this.platformName,
    required this.loginIp,
    required this.loginLocation,
    required this.userAgent,
    required this.loginResult,
    required this.failReason,
    required this.createTime,
  });

  final String platformCode;
  final String platformName;
  final String loginIp;
  final String loginLocation;
  final String userAgent;
  final bool loginResult;
  final String failReason;
  final String createTime;

  factory SecurityLoginLog.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const SecurityLoginLog(
        platformCode: '',
        platformName: '',
        loginIp: '',
        loginLocation: '',
        userAgent: '',
        loginResult: false,
        failReason: '',
        createTime: '',
      );
    }

    return SecurityLoginLog(
      platformCode: (value['platform_code'] ?? '').toString().trim(),
      platformName: (value['platform_name'] ?? '').toString().trim(),
      loginIp: (value['login_ip'] ?? '').toString().trim(),
      loginLocation: (value['login_location'] ?? '').toString().trim(),
      userAgent: (value['user_agent'] ?? '').toString().trim(),
      loginResult: SecurityOverview._intValue(value['login_result']) == 1,
      failReason: (value['fail_reason'] ?? '').toString().trim(),
      createTime: (value['create_time'] ?? '').toString().trim(),
    );
  }
}

class DiagnosticUploadReceipt {
  const DiagnosticUploadReceipt({
    required this.id,
    required this.entryCount,
    required this.uploadedAt,
  });

  final int id;
  final int entryCount;
  final String uploadedAt;

  factory DiagnosticUploadReceipt.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const DiagnosticUploadReceipt(
        id: 0,
        entryCount: 0,
        uploadedAt: '',
      );
    }

    return DiagnosticUploadReceipt(
      id: SecurityOverview._intValue(value['id']),
      entryCount: SecurityOverview._intValue(value['entry_count']),
      uploadedAt: (value['uploaded_at'] ?? '').toString().trim(),
    );
  }
}
