class AuthSession {
  const AuthSession({
    required this.token,
    required this.member,
    required this.profile,
    required this.doctorProfile,
    required this.currentRole,
    required this.roleFlags,
  });

  final AuthToken token;
  final Map<String, dynamic> member;
  final Map<String, dynamic> profile;
  final Map<String, dynamic> doctorProfile;
  final String currentRole;
  final AuthRoleFlags roleFlags;

  String get memberId => (member['id'] ?? '').toString();

  String get profileRole => roleFlags.profileRole;

  bool get isDoctor => roleFlags.isDoctor;

  bool get isPatient => roleFlags.isPatient;

  bool get isDoctorApproved => roleFlags.doctorApproved;

  factory AuthSession.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected auth session shape');
    }

    final profile = _map(value['profile']);
    final doctorProfile = _map(value['doctor_profile']);

    return AuthSession(
      token: AuthToken.fromJson(value['token']),
      member: _map(value['member']),
      profile: profile,
      doctorProfile: doctorProfile,
      currentRole: _resolveCurrentRole(
        value['current_role'],
        profile,
        doctorProfile,
      ),
      roleFlags: AuthRoleFlags.fromJson(
        value['role_flags'],
        profile,
        doctorProfile,
      ),
    );
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return const <String, dynamic>{};
  }

  static String _resolveCurrentRole(
    Object? value,
    Map<String, dynamic> profile,
    Map<String, dynamic> doctorProfile,
  ) {
    final normalized = _normalizeRole((value ?? '').toString());
    if (normalized.isNotEmpty) {
      return normalized;
    }

    final profileRole = _normalizeRole(
      (profile['member_role'] ?? '').toString(),
    );
    final doctorApproved =
        _intValue(doctorProfile['audit_status']) == 1 &&
        _intValue(doctorProfile['status'], fallback: 1) == 1;

    return profileRole == 'doctor' && doctorApproved ? 'doctor' : 'patient';
  }

  static String _normalizeRole(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'doctor'
        ? 'doctor'
        : normalized == 'patient'
        ? 'patient'
        : '';
  }

  static int _intValue(Object? value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }
}

class AuthRoleFlags {
  const AuthRoleFlags({
    required this.profileRole,
    required this.isPatient,
    required this.isDoctor,
    required this.doctorProfileSubmitted,
    required this.doctorApproved,
  });

  final String profileRole;
  final bool isPatient;
  final bool isDoctor;
  final bool doctorProfileSubmitted;
  final bool doctorApproved;

  factory AuthRoleFlags.fromJson(
    Object? value,
    Map<String, dynamic> profile,
    Map<String, dynamic> doctorProfile,
  ) {
    final json = value is Map<String, dynamic>
        ? value
        : const <String, dynamic>{};
    final fallbackProfileRole = AuthSession._normalizeRole(
      (profile['member_role'] ?? '').toString(),
    );
    final profileRole = AuthSession._normalizeRole(
      (json['profile_role'] ?? '').toString(),
    );
    final doctorSubmitted = json['doctor_profile_submitted'] is bool
        ? json['doctor_profile_submitted'] as bool
        : doctorProfile.isNotEmpty;
    final doctorApproved = json['doctor_approved'] is bool
        ? json['doctor_approved'] as bool
        : AuthSession._intValue(doctorProfile['audit_status']) == 1 &&
              AuthSession._intValue(doctorProfile['status'], fallback: 1) == 1;
    final isDoctor = json['is_doctor'] is bool
        ? json['is_doctor'] as bool
        : ((profileRole.isNotEmpty ? profileRole : fallbackProfileRole) ==
                  'doctor' &&
              doctorApproved);
    final isPatient = json['is_patient'] is bool
        ? json['is_patient'] as bool
        : !isDoctor;

    return AuthRoleFlags(
      profileRole: profileRole.isNotEmpty
          ? profileRole
          : (fallbackProfileRole.isNotEmpty ? fallbackProfileRole : 'patient'),
      isPatient: isPatient,
      isDoctor: isDoctor,
      doctorProfileSubmitted: doctorSubmitted,
      doctorApproved: doctorApproved,
    );
  }
}

class AuthToken {
  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  factory AuthToken.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected auth token shape');
    }

    return AuthToken(
      accessToken: (value['access_token'] as String?) ?? '',
      refreshToken: (value['refresh_token'] as String?) ?? '',
      tokenType: (value['token_type'] as String?) ?? 'Bearer',
      expiresIn: (value['expires_in'] as num?)?.toInt() ?? 0,
    );
  }
}

class VerificationCodeDelivery {
  const VerificationCodeDelivery({
    required this.sent,
    required this.target,
    required this.expiresIn,
    required this.resendAfter,
  });

  final bool sent;
  final String target;
  final int expiresIn;
  final int resendAfter;

  factory VerificationCodeDelivery.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected verification code shape');
    }

    return VerificationCodeDelivery(
      sent: value['sent'] == true || value['sent'] == 'true',
      target: (value['target'] as String?) ?? '',
      expiresIn: (value['expires_in'] as num?)?.toInt() ?? 0,
      resendAfter: (value['resend_after'] as num?)?.toInt() ?? 0,
    );
  }
}
