class ApiResult<T> {
  const ApiResult({
    required this.code,
    required this.message,
    this.data,
    this.traceId,
  });

  final int code;
  final String message;
  final T? data;
  final String? traceId;

  bool get isSuccess => code == 200;

  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) decode,
  ) {
    return ApiResult<T>(
      code: (json['code'] as num?)?.toInt() ?? 500,
      message: (json['message'] as String?) ?? 'unknown',
      data: json.containsKey('data') ? decode(json['data']) : null,
      traceId: json['trace_id'] as String?,
    );
  }
}
