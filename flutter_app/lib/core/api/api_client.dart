import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import 'api_result.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({
    required SecureTokenStorage tokenStorage,
    String? baseUrl,
    Dio? dio,
  }) : dio =
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
  }

  static const apiBaseUrl = String.fromEnvironment(
    'HELP_SUPPORT_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8787',
  );

  final Dio dio;

  Future<ApiResult<T>> getApi<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Object? value) decode,
  }) async {
    final response = await dio.get<Object?>(
      path,
      queryParameters: queryParameters,
    );
    return _decode(response.data, decode);
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
    return _decode(response.data, decode);
  }

  Future<ApiResult<T>> putApi<T>(
    String path, {
    Object? data,
    required T Function(Object? value) decode,
  }) async {
    final response = await dio.put<Object?>(path, data: data);
    return _decode(response.data, decode);
  }

  ApiResult<T> _decode<T>(Object? data, T Function(Object? value) decode) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected API response shape');
    }

    final result = ApiResult<T>.fromJson(data, decode);
    if (!result.isSuccess) {
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
