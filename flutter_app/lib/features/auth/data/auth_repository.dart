import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<RegisterEmailCodeDelivery> sendRegisterEmailCode({
    required String email,
  }) async {
    final result = await _apiClient.postApi<RegisterEmailCodeDelivery>(
      '/app/help/auth/register-email-code',
      data: {'email': email},
      decode: RegisterEmailCodeDelivery.fromJson,
    );
    final delivery = result.data;
    if (delivery == null) {
      throw const FormatException('注册邮箱验证码响应缺少 data');
    }
    return delivery;
  }

  Future<AuthSession> accountRegister({
    required String username,
    required String email,
    required String password,
    required String emailCode,
    required String memberRole,
    String? locale,
    String? nickname,
  }) {
    return _postSession('/app/help/auth/account-register', {
      'username': username,
      'email': email,
      'password': password,
      'email_code': emailCode,
      'member_role': memberRole,
      if (locale != null && locale.trim().isNotEmpty) 'locale': locale,
      if (nickname != null && nickname.trim().isNotEmpty)
        'nickname': nickname.trim(),
    });
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

  Future<AuthProtocolDocument> fetchProtocol(AuthProtocolType type) async {
    final result = await _apiClient.getApi<AuthProtocolDocument>(
      '/app/help/common/protocol',
      queryParameters: {'type': type.code},
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
}
