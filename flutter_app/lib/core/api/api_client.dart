import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import '../diagnostics/diagnostic_log_interceptor.dart';
import '../diagnostics/diagnostic_log_service.dart';
import 'api_result.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({
    required SecureTokenStorage tokenStorage,
    DiagnosticLogService? diagnosticLogService,
    String? baseUrl,
    Dio? dio,
  }) : _diagnosticLogService = diagnosticLogService,
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

  static const apiBaseUrl = String.fromEnvironment(
    'HELP_SUPPORT_API_BASE_URL',
    defaultValue: 'http://10.0.0.6:8787',
  );

  final DiagnosticLogService? _diagnosticLogService;
  final Dio dio;

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
    final response = await dio.get<Object?>(
      path,
      queryParameters: queryParameters,
    );
    return _decode(response.data, decode, path: path);
  }

  Future<ApiResult<T>> postApi<T>(
    String path, {
    Object? data,
    Options? options,
    required T Function(Object? value) decode,
  }) async {
    final response = await dio.post<Object?>(
      path,
      data: data,
      options: options,
    );
    return _decode(response.data, decode, path: path);
  }

  Future<ApiResult<T>> putApi<T>(
    String path, {
    Object? data,
    required T Function(Object? value) decode,
  }) async {
    final response = await dio.put<Object?>(path, data: data);
    return _decode(response.data, decode, path: path);
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
