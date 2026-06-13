import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  const SecureTokenStorage([this._storage = const FlutterSecureStorage()]);

  static const _accessTokenKey = 'helpsupport.access_token';
  static const _refreshTokenKey = 'helpsupport.refresh_token';
  static const _memberIdKey = 'helpsupport.member_id';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<String?> readMemberId() => _storage.read(key: _memberIdKey);

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String memberId,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _memberIdKey, value: memberId),
    ]);
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _memberIdKey),
    ]);
  }
}
