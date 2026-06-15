import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum DiagnosticLogLevel { info, warning, error }

class DiagnosticLogEntry {
  const DiagnosticLogEntry({
    required this.id,
    required this.level,
    required this.category,
    required this.message,
    required this.details,
    required this.createdAt,
  });

  final String id;
  final DiagnosticLogLevel level;
  final String category;
  final String message;
  final String details;
  final DateTime createdAt;

  factory DiagnosticLogEntry.fromJson(Map<String, dynamic> json) {
    return DiagnosticLogEntry(
      id: (json['id'] ?? '').toString().trim(),
      level: DiagnosticLogLevel.values.firstWhere(
        (item) => item.name == (json['level'] ?? '').toString().trim(),
        orElse: () => DiagnosticLogLevel.info,
      ),
      category: (json['category'] ?? '').toString().trim(),
      message: (json['message'] ?? '').toString().trim(),
      details: (json['details'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level.name,
      'category': category,
      'message': message,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class DiagnosticLogService {
  static const _fileName = 'diagnostic_logs.json';
  static const _maxEntries = 200;
  static const _maxCategoryLength = 80;
  static const _maxMessageLength = 400;
  static const _maxDetailsLength = 12000;

  Future<void> _queue = Future<void>.value();
  Future<File>? _logFileFuture;

  Future<void> recordInfo({
    required String category,
    required String message,
    Object? details,
  }) {
    return _record(
      level: DiagnosticLogLevel.info,
      category: category,
      message: message,
      details: details,
    );
  }

  Future<void> recordWarning({
    required String category,
    required String message,
    Object? details,
  }) {
    return _record(
      level: DiagnosticLogLevel.warning,
      category: category,
      message: message,
      details: details,
    );
  }

  Future<void> recordError({
    required String category,
    required String message,
    Object? details,
  }) {
    return _record(
      level: DiagnosticLogLevel.error,
      category: category,
      message: message,
      details: details,
    );
  }

  Future<void> recordApiFailure({
    required String path,
    required int code,
    required String message,
    String? traceId,
  }) {
    return recordError(
      category: 'api',
      message: '$path -> $code',
      details: {
        'message': message,
        if (traceId != null && traceId.trim().isNotEmpty) 'trace_id': traceId,
      },
    );
  }

  Future<void> recordDioException(DioException error) {
    final request = error.requestOptions;
    final statusCode = error.response?.statusCode;
    return recordError(
      category: 'network',
      message:
          '${request.method.toUpperCase()} ${request.path}${statusCode == null ? '' : ' -> $statusCode'}',
      details: {
        'type': error.type.name,
        'message': error.message ?? error.error?.toString() ?? '',
      },
    );
  }

  Future<void> recordFlutterError(FlutterErrorDetails details) {
    return recordError(
      category: 'flutter',
      message: details.exceptionAsString(),
      details: {
        if (details.library?.trim().isNotEmpty ?? false)
          'library': details.library!.trim(),
        if (details.context != null) 'context': details.context.toString(),
        if (details.stack != null) 'stack_trace': details.stack.toString(),
      },
    );
  }

  Future<void> recordUnhandledError(Object error, StackTrace stackTrace) {
    return recordError(
      category: 'platform',
      message: error.toString(),
      details: {'stack_trace': stackTrace.toString()},
    );
  }

  Future<List<DiagnosticLogEntry>> readEntries({bool newestFirst = true}) {
    return _enqueue(() async {
      final entries = await _readEntriesInternal();
      if (!newestFirst) {
        return entries;
      }
      return entries.reversed.toList(growable: false);
    });
  }

  Future<void> clear() {
    return _enqueue(() async {
      await _writeEntriesInternal(const []);
    });
  }

  Future<void> _record({
    required DiagnosticLogLevel level,
    required String category,
    required String message,
    Object? details,
  }) {
    final normalizedMessage = _normalizeText(message, _maxMessageLength);
    if (normalizedMessage.isEmpty) {
      return Future<void>.value();
    }
    final entry = DiagnosticLogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      level: level,
      category: _normalizeText(category, _maxCategoryLength, fallback: 'app'),
      message: normalizedMessage,
      details: _normalizeDetails(details),
      createdAt: DateTime.now(),
    );

    return _enqueue(() async {
      final entries = await _readEntriesInternal();
      final next = [...entries, entry];
      final overflow = next.length - _maxEntries;
      if (overflow > 0) {
        next.removeRange(0, overflow);
      }
      await _writeEntriesInternal(next);
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _queue = _queue.catchError((_) {}).then((_) async {
      try {
        completer.complete(await action());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<List<DiagnosticLogEntry>> _readEntriesInternal() async {
    final file = await _logFile();
    if (!await file.exists()) {
      return const [];
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(DiagnosticLogEntry.fromJson)
          .where((item) => item.message.isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      await file.writeAsString('[]');
      return const [];
    }
  }

  Future<void> _writeEntriesInternal(List<DiagnosticLogEntry> entries) async {
    final file = await _logFile();
    await file.writeAsString(
      jsonEncode(entries.map((item) => item.toJson()).toList()),
      flush: true,
    );
  }

  Future<File> _logFile() {
    return _logFileFuture ??= _createLogFile();
  }

  Future<File> _createLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/diagnostics/$_fileName');
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.writeAsString('[]', flush: true);
    }
    return file;
  }

  String _normalizeText(String value, int maxLength, {String fallback = ''}) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return fallback;
    }
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength)}...';
  }

  String _normalizeDetails(Object? details) {
    final text = switch (details) {
      null => '',
      String value => value.trim(),
      StackTrace value => value.toString().trim(),
      _ => _encodeStructured(details),
    };
    if (text.length <= _maxDetailsLength) {
      return text;
    }
    return '${text.substring(0, _maxDetailsLength)}...';
  }

  String _encodeStructured(Object? value) {
    final normalized = _normalizeStructuredValue(value);
    try {
      return const JsonEncoder.withIndent('  ').convert(normalized);
    } on Object {
      return normalized.toString();
    }
  }

  Object? _normalizeStructuredValue(Object? value) {
    return switch (value) {
      null => null,
      num() || bool() => value,
      String() => value,
      DateTime() => value.toIso8601String(),
      Uri() => value.toString(),
      Map() => value.map(
        (key, entry) =>
            MapEntry(key.toString(), _normalizeStructuredValue(entry)),
      ),
      List() => value.map(_normalizeStructuredValue).toList(growable: false),
      Set() => value.map(_normalizeStructuredValue).toList(growable: false),
      DiagnosticLogLevel() => value.name,
      DioExceptionType() => value.name,
      _ => value.toString(),
    };
  }
}
