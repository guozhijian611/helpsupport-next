import 'package:dio/dio.dart';

import '../auth/token_storage.dart';

class AuthInterceptor extends Interceptor {
  static const _publicPrefixes = <String>['/app/help/auth', '/app/help/common'];

  AuthInterceptor(this._tokenStorage);

  final SecureTokenStorage _tokenStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _attachToken(options, handler);
  }

  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.headers.containsKey('Authorization')) {
      handler.next(options);
      return;
    }
    if (!_shouldAttachToken(options)) {
      handler.next(options);
      return;
    }

    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  bool _shouldAttachToken(RequestOptions options) {
    final rawPath = options.path.trim();
    if (rawPath.isEmpty) {
      return true;
    }

    final path = Uri.tryParse(rawPath)?.path ?? rawPath;
    for (final prefix in _publicPrefixes) {
      if (path == prefix || path.startsWith('$prefix/')) {
        return false;
      }
    }
    return true;
  }
}
