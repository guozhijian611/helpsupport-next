import 'package:dio/dio.dart';

import 'diagnostic_log_service.dart';

class DiagnosticLogInterceptor extends Interceptor {
  DiagnosticLogInterceptor(this._diagnosticLogService);

  final DiagnosticLogService _diagnosticLogService;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      await _diagnosticLogService.recordDioException(err);
    } on Object {
      // Diagnostic logging should never block the request lifecycle.
    }
    handler.next(err);
  }
}
