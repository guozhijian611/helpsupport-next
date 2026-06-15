class AuthSession {
  const AuthSession({
    required this.token,
    required this.member,
    required this.profile,
    required this.doctorProfile,
  });

  final AuthToken token;
  final Map<String, dynamic> member;
  final Map<String, dynamic> profile;
  final Map<String, dynamic> doctorProfile;

  String get memberId => (member['id'] ?? '').toString();

  factory AuthSession.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected auth session shape');
    }

    return AuthSession(
      token: AuthToken.fromJson(value['token']),
      member: _map(value['member']),
      profile: _map(value['profile']),
      doctorProfile: _map(value['doctor_profile']),
    );
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return const <String, dynamic>{};
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

class RegisterEmailCodeDelivery {
  const RegisterEmailCodeDelivery({
    required this.sent,
    required this.email,
    required this.expiresIn,
    required this.resendAfter,
  });

  final bool sent;
  final String email;
  final int expiresIn;
  final int resendAfter;

  factory RegisterEmailCodeDelivery.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected register email code shape');
    }

    return RegisterEmailCodeDelivery(
      sent: value['sent'] == true || value['sent'] == 'true',
      email: (value['email'] as String?) ?? '',
      expiresIn: (value['expires_in'] as num?)?.toInt() ?? 0,
      resendAfter: (value['resend_after'] as num?)?.toInt() ?? 0,
    );
  }
}
