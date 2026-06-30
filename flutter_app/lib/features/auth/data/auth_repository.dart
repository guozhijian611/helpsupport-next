import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/token_storage.dart';
import 'auth_models.dart';
import 'auth_protocol.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;
  bool _googleInitialized = false;

  Future<AuthSession> accountLogin({
    required String username,
    required String password,
  }) {
    return _postSession('/app/help/auth/account-login', {
      'username': username,
      'password': password,
    });
  }

  Future<VerificationCodeDelivery> sendRegisterEmailCode({
    required String email,
  }) async {
    final result = await _apiClient.postApi<VerificationCodeDelivery>(
      '/app/help/auth/register-email-code',
      data: {'email': email},
      decode: VerificationCodeDelivery.fromJson,
    );
    final delivery = result.data;
    if (delivery == null) {
      throw const FormatException('注册邮箱验证码响应缺少 data');
    }
    return delivery;
  }

  Future<VerificationCodeDelivery> sendRegisterPhoneCode({
    required String mobile,
  }) async {
    final result = await _apiClient.postApi<VerificationCodeDelivery>(
      '/app/help/auth/register-phone-code',
      data: {'mobile': mobile},
      decode: VerificationCodeDelivery.fromJson,
    );
    final delivery = result.data;
    if (delivery == null) {
      throw const FormatException('注册手机验证码响应缺少 data');
    }
    return delivery;
  }

  Future<VerificationCodeDelivery> sendForgotEmailCode({
    required String email,
  }) async {
    final result = await _apiClient.postApi<VerificationCodeDelivery>(
      '/app/help/auth/forgot-email-code',
      data: {'email': email},
      decode: VerificationCodeDelivery.fromJson,
    );
    final delivery = result.data;
    if (delivery == null) {
      throw const FormatException('找回密码邮箱验证码响应缺少 data');
    }
    return delivery;
  }

  Future<VerificationCodeDelivery> sendForgotPhoneCode({
    required String mobile,
  }) async {
    final result = await _apiClient.postApi<VerificationCodeDelivery>(
      '/app/help/auth/forgot-phone-code',
      data: {'mobile': mobile},
      decode: VerificationCodeDelivery.fromJson,
    );
    final delivery = result.data;
    if (delivery == null) {
      throw const FormatException('找回密码手机验证码响应缺少 data');
    }
    return delivery;
  }

  Future<AuthSession> accountRegister({
    required String registerType,
    String? username,
    String? email,
    String? mobile,
    required String password,
    String? emailCode,
    String? mobileCode,
    required String memberRole,
    String? locale,
    String? timezone,
    String? nickname,
  }) {
    return _postSession('/app/help/auth/account-register', {
      'register_type': registerType,
      if (username != null && username.trim().isNotEmpty)
        'username': username.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (mobile != null && mobile.trim().isNotEmpty) 'mobile': mobile.trim(),
      'password': password,
      if (emailCode != null && emailCode.trim().isNotEmpty)
        'email_code': emailCode.trim(),
      if (mobileCode != null && mobileCode.trim().isNotEmpty)
        'mobile_code': mobileCode.trim(),
      'member_role': memberRole,
      if (locale != null && locale.trim().isNotEmpty) 'locale': locale,
      if (timezone != null && timezone.trim().isNotEmpty) 'timezone': timezone,
      if (nickname != null && nickname.trim().isNotEmpty)
        'nickname': nickname.trim(),
    });
  }

  Future<void> passwordReset({
    required String resetType,
    String? email,
    String? mobile,
    String? emailCode,
    String? mobileCode,
    required String password,
  }) {
    return _postSuccess('/app/help/auth/password-reset', {
      'reset_type': resetType,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (mobile != null && mobile.trim().isNotEmpty) 'mobile': mobile.trim(),
      if (emailCode != null && emailCode.trim().isNotEmpty)
        'email_code': emailCode.trim(),
      if (mobileCode != null && mobileCode.trim().isNotEmpty)
        'mobile_code': mobileCode.trim(),
      'password': password,
    });
  }

  Future<void> saveProfile({
    required String nickname,
    int? gender,
    String? birthday,
    String? memberRole,
  }) {
    return _postSuccess('/app/help/me/profile/save', {
      'nickname': nickname.trim(),
      if (gender != null) 'gender': gender,
      if (birthday != null && birthday.trim().isNotEmpty) 'birthday': birthday,
      if (memberRole != null && memberRole.trim().isNotEmpty)
        'member_role': memberRole.trim(),
    });
  }

  Future<String> uploadDoctorCertificationImage({required XFile file}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    final result = await _apiClient.postApi<String>(
      '/app/help/me/doctor-certification/upload-image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return (value['url'] ?? '').toString();
        }
        throw const FormatException(
          'Unexpected doctor certification upload response',
        );
      },
    );
    final url = result.data?.trim() ?? '';
    if (url.isEmpty) {
      throw const FormatException('医生资质图片上传失败');
    }
    return url;
  }

  Future<Map<String, dynamic>> saveDoctorCertification({
    required String realName,
    required String licenseNo,
    String? title,
    String? hospital,
    String? department,
    String? specialty,
    List<String> certificationImages = const [],
  }) async {
    final result = await _apiClient.postApi<Map<String, dynamic>>(
      '/app/help/me/doctor-certification',
      data: {
        'real_name': realName.trim(),
        'license_no': licenseNo.trim(),
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (hospital != null && hospital.trim().isNotEmpty)
          'hospital': hospital.trim(),
        if (department != null && department.trim().isNotEmpty)
          'department': department.trim(),
        if (specialty != null && specialty.trim().isNotEmpty)
          'specialty': specialty.trim(),
        'certification_images': certificationImages,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value;
        }
        throw const FormatException('Unexpected doctor certification response');
      },
    );
    return result.data ?? const <String, dynamic>{};
  }

  Future<AuthSession> googleLogin() async {
    await _initializeGoogle();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError('当前平台不支持 Google 交互登录');
    }

    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google ID Token 获取失败');
    }

    return _postSession('/app/help/auth/google', {'id_token': idToken});
  }

  Future<AuthSession> appleLogin() async {
    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw StateError('当前平台不支持 Apple 登录');
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw StateError('Apple identityToken 获取失败');
    }

    final fullName = [
      credential.givenName,
      credential.familyName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

    return _postSession('/app/help/auth/apple', {
      'identity_token': identityToken,
      if (fullName.isNotEmpty) 'full_name': fullName,
    });
  }

  Future<AuthSession> refreshSession() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('Refresh token 不存在');
    }

    return _postSession(
      '/app/help/auth/refresh',
      const <String, dynamic>{},
      options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
    );
  }

  Future<AuthProtocolDocument> fetchProtocol(
    AuthProtocolType type, {
    String? locale,
  }) async {
    final normalizedLocale = locale?.trim() ?? '';
    final result = await _apiClient.getApi<AuthProtocolDocument>(
      '/app/help/common/protocol',
      queryParameters: {
        'type': type.code,
        if (normalizedLocale.isNotEmpty) 'locale': normalizedLocale,
      },
      decode: (value) => AuthProtocolDocument.fromJson(value, type),
    );
    final document = result.data;
    if (document == null) {
      throw const FormatException('协议响应缺少 data');
    }

    return document;
  }

  Future<void> saveSession(AuthSession session) {
    return _tokenStorage.saveSession(
      accessToken: session.token.accessToken,
      refreshToken: session.token.refreshToken,
      memberId: session.memberId,
    );
  }

  Future<void> clearSession() => _tokenStorage.clearSession();

  Future<void> signOutIdentityProviders() async {
    if (!_googleInitialized) {
      return;
    }
    await GoogleSignIn.instance.signOut();
  }

  Future<AuthSession> _postSession(
    String path,
    Map<String, dynamic> data, {
    Options? options,
  }) async {
    final result = await _apiClient.postApi<AuthSession>(
      path,
      data: data,
      options: options,
      decode: AuthSession.fromJson,
    );
    final session = result.data;
    if (session == null || session.token.accessToken.isEmpty) {
      throw const FormatException('登录响应缺少 token');
    }
    return session;
  }

  Future<void> _initializeGoogle() async {
    if (_googleInitialized) {
      return;
    }
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<void> _postSuccess(String path, Map<String, dynamic> data) async {
    await _apiClient.postApi<Object?>(
      path,
      data: data,
      decode: (value) => value,
    );
  }
}
