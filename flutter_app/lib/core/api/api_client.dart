import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/session_invalidation_notifier.dart';
import '../auth/token_storage.dart';
import '../diagnostics/diagnostic_log_interceptor.dart';
import '../diagnostics/diagnostic_log_service.dart';
import 'api_result.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({
    required SecureTokenStorage tokenStorage,
    required SessionInvalidationNotifier sessionInvalidationNotifier,
    DiagnosticLogService? diagnosticLogService,
    String? baseUrl,
    Dio? dio,
  }) : _diagnosticLogService = diagnosticLogService,
       _sessionInvalidationNotifier = sessionInvalidationNotifier,
       _tokenStorage = tokenStorage,
       dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl ?? apiBaseUrl,
               connectTimeout: const Duration(seconds: 12),
               receiveTimeout: const Duration(seconds: 20),
               headers: const {'Accept': 'application/json'},
             ),
           ) {
    this.dio.interceptors.add(AuthInterceptor(tokenStorage));
    if (diagnosticLogService != null) {
      this.dio.interceptors.add(DiagnosticLogInterceptor(diagnosticLogService));
    }
  }

  static const apiBaseUrl = 'http://10.0.0.6:8787';
  static const aiCallDebugOverlayEnabled = true;
  static const _refreshPath = '/app/help/auth/refresh';
  static const _authPublicPrefixes = <String>[
    '/app/help/auth',
    '/app/help/common',
  ];

  final DiagnosticLogService? _diagnosticLogService;
  final SessionInvalidationNotifier _sessionInvalidationNotifier;
  final SecureTokenStorage _tokenStorage;
  final Dio dio;
  Future<void>? _sessionRefreshFuture;

  String resolveUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return trimmed;
    }

    final baseUri = Uri.parse(dio.options.baseUrl);
    if (trimmed.startsWith('//')) {
      return '${baseUri.scheme}:$trimmed';
    }

    return baseUri
        .resolve(trimmed.startsWith('/') ? trimmed : '/$trimmed')
        .toString();
  }

  Future<ApiResult<T>> getApi<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Object? value) decode,
  }) async {
    return _sendWithSessionRefresh(
      path: path,
      request: () => dio.get<Object?>(path, queryParameters: queryParameters),
      decode: decode,
    );
  }

  Future<ApiResult<T>> postApi<T>(
    String path, {
    Object? data,
    Options? options,
    ProgressCallback? onSendProgress,
    required T Function(Object? value) decode,
  }) async {
    return _sendWithSessionRefresh(
      path: path,
      request: () => dio.post<Object?>(
        path,
        data: data,
        options: options,
        onSendProgress: onSendProgress,
      ),
      decode: decode,
    );
  }

  Future<ApiResult<T>> putApi<T>(
    String path, {
    Object? data,
    required T Function(Object? value) decode,
  }) async {
    return _sendWithSessionRefresh(
      path: path,
      request: () => dio.put<Object?>(path, data: data),
      decode: decode,
    );
  }

  Future<String> readAccessToken() async {
    final token = await _tokenStorage.readAccessToken();
    return token?.trim() ?? '';
  }

  Future<ApiResult<T>> _sendWithSessionRefresh<T>({
    required String path,
    required Future<Response<Object?>> Function() request,
    required T Function(Object? value) decode,
  }) async {
    try {
      final response = await request();
      return _decode(response.data, decode, path: path);
    } on ApiException catch (error, stackTrace) {
      if (!_isSessionExpired(error.code, error.message) ||
          !_shouldAttemptRefresh(path)) {
        rethrow;
      }
      return _refreshAndRetry(
        path: path,
        request: request,
        decode: decode,
        originalError: error,
        originalStackTrace: stackTrace,
      );
    } on DioException catch (error) {
      if (!_isTransportAuthFailure(error) || !_shouldAttemptRefresh(path)) {
        rethrow;
      }
      return _refreshAndRetry(
        path: path,
        request: request,
        decode: decode,
        originalError: error,
        originalStackTrace: error.stackTrace,
      );
    }
  }

  Future<ApiResult<T>> _refreshAndRetry<T>({
    required String path,
    required Future<Response<Object?>> Function() request,
    required T Function(Object? value) decode,
    required Object originalError,
    required StackTrace originalStackTrace,
  }) async {
    try {
      await _refreshSessionOnce();
    } on Object {
      await _invalidateSession();
      Error.throwWithStackTrace(originalError, originalStackTrace);
    }

    try {
      final response = await request();
      return _decode(response.data, decode, path: path);
    } on ApiException catch (error) {
      if (_isSessionExpired(error.code, error.message)) {
        await _invalidateSession();
      }
      rethrow;
    } on DioException catch (error) {
      if (_isTransportAuthFailure(error)) {
        await _invalidateSession();
      }
      rethrow;
    }
  }

  ApiResult<T> _decode<T>(
    Object? data,
    T Function(Object? value) decode, {
    required String path,
  }) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected API response shape');
    }

    final result = ApiResult<T>.fromJson(data, decode);
    if (!result.isSuccess) {
      final future = _diagnosticLogService?.recordApiFailure(
        path: path,
        code: result.code,
        message: result.message,
        traceId: result.traceId,
      );
      if (future != null) {
        unawaited(future.catchError((_) {}));
      }
      throw ApiException(
        code: result.code,
        message: result.message,
        traceId: result.traceId,
      );
    }

    return result;
  }

  bool _isSessionExpired(int code, String message) {
    if (code == 401) {
      return true;
    }
    if (code != 400) {
      return false;
    }

    final normalized = message.trim();
    const authMarkers = <String>[
      '请重新登录',
      '登录凭证',
      '用户信息读取失败',
      '会员登录状态异常',
      '未登录',
    ];
    return authMarkers.any(normalized.contains);
  }

  bool _isTransportAuthFailure(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == 401 || statusCode == 403;
  }

  bool _shouldAttemptRefresh(String path) {
    final normalized = _pathOnly(path);
    if (normalized == _refreshPath) {
      return false;
    }
    for (final prefix in _authPublicPrefixes) {
      if (normalized == prefix || normalized.startsWith('$prefix/')) {
        return false;
      }
    }
    return true;
  }

  String _pathOnly(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return Uri.tryParse(trimmed)?.path ?? trimmed;
  }

  Future<void> _refreshSessionOnce() {
    final pending = _sessionRefreshFuture;
    if (pending != null) {
      return pending;
    }

    final refreshFuture = _performSessionRefresh();
    _sessionRefreshFuture = refreshFuture;
    return refreshFuture.whenComplete(() {
      if (identical(_sessionRefreshFuture, refreshFuture)) {
        _sessionRefreshFuture = null;
      }
    });
  }

  Future<void> _performSessionRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('Refresh token 不存在');
    }

    final response = await dio.post<Object?>(
      _refreshPath,
      data: const <String, dynamic>{},
      options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
    );
    final result = _decode<Map<String, dynamic>>(response.data, (value) {
      if (value is Map<String, dynamic>) {
        return value;
      }
      throw const FormatException('Unexpected auth refresh response');
    }, path: _refreshPath);
    final session = result.data;
    if (session == null) {
      throw const FormatException('刷新登录响应缺少 data');
    }

    final token = session['token'];
    if (token is! Map<String, dynamic>) {
      throw const FormatException('刷新登录响应缺少 token');
    }

    final accessToken = (token['access_token'] ?? '').toString().trim();
    final nextRefreshToken = (token['refresh_token'] ?? '').toString().trim();
    final member = session['member'];
    final memberId = member is Map<String, dynamic>
        ? (member['id'] ?? '').toString().trim()
        : '';
    if (accessToken.isEmpty || nextRefreshToken.isEmpty || memberId.isEmpty) {
      throw const FormatException('刷新登录响应缺少必要凭证');
    }

    await _tokenStorage.saveSession(
      accessToken: accessToken,
      refreshToken: nextRefreshToken,
      memberId: memberId,
    );
  }

  Future<void> _invalidateSession() async {
    await _tokenStorage.clearSession();
    _sessionInvalidationNotifier.notify();
  }
}

class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.traceId});

  final int code;
  final String message;
  final String? traceId;

  @override
  String toString() {
    return 'ApiException(code: $code, message: $message, traceId: $traceId)';
  }
}
