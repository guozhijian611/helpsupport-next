import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import 'chat_models.dart';

class ChatRepository {
  const ChatRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<ChatOverview> fetchOverview() async {
    final result = await _apiClient.getApi<ChatOverview>(
      '/app/help/chat/overview',
      decode: ChatOverview.fromJson,
    );
    return result.data ?? const ChatOverview(modes: [], recentSessions: []);
  }

  Future<ChatConfig?> fetchConfig(String chatMode) async {
    final result = await _apiClient.getApi<List<ChatConfig>>(
      '/app/help/chat/config',
      queryParameters: {'chat_mode': chatMode},
      decode: (value) => _decodeList(value, ChatConfig.fromJson),
    );
    final configs = result.data ?? const <ChatConfig>[];
    return configs.isEmpty ? null : configs.first;
  }

  Future<List<AiRobotProfile>> fetchRobotProfiles(String runtimeMode) async {
    final result = await _apiClient.getApi<List<AiRobotProfile>>(
      '/app/help/chat/robot-profiles',
      queryParameters: {'runtime_mode': runtimeMode},
      decode: (value) => _decodeList(
        value,
        (json) =>
            AiRobotProfile.fromJson(json, fallbackRuntimeMode: runtimeMode),
      ),
    );
    return result.data ?? const [];
  }

  Future<ChatRealtimeConfig> fetchRealtimeConfig() async {
    final result = await _apiClient.getApi<ChatRealtimeConfig>(
      '/app/help/chat/realtime-config',
      decode: ChatRealtimeConfig.fromJson,
    );
    final config = result.data;
    if (config == null || config.wsUrl.trim().isEmpty) {
      throw const FormatException('实时音视频配置无效');
    }
    return config;
  }

  Future<String> readAccessToken() {
    return _apiClient.readAccessToken();
  }

  Future<ChatConfig> saveConfig({
    required String chatMode,
    required String promptText,
  }) async {
    final result = await _apiClient.postApi<ChatConfig>(
      '/app/help/chat/config',
      data: {'chat_mode': chatMode, 'prompt_text': promptText},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return ChatConfig.fromJson(value);
        }
        throw const FormatException('Unexpected chat config shape');
      },
    );
    final config = result.data;
    if (config == null || config.promptText.trim().isEmpty) {
      throw const FormatException('聊天提示词保存失败');
    }
    return config;
  }

  Future<ChatPage<ChatSession>> fetchSessions({String? chatMode}) async {
    final result = await _apiClient.getApi<ChatPage<ChatSession>>(
      '/app/help/chat/sessions',
      queryParameters: {
        if (chatMode != null && chatMode.isNotEmpty) 'chat_mode': chatMode,
      },
      decode: (value) => ChatPage.fromJson(value, ChatSession.fromJson),
    );
    return result.data ??
        const ChatPage(list: [], total: 0, page: 1, pageSize: 20);
  }

  Future<ChatSession> createSession(
    String chatMode, {
    String locale = '',
  }) async {
    final result = await _apiClient.postApi<ChatSession>(
      '/app/help/chat/session',
      data: {
        'chat_mode': chatMode,
        'is_pinned': 2,
        if (locale.isNotEmpty) 'locale': locale,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return ChatSession.fromJson(value);
        }
        throw const FormatException('Unexpected chat session shape');
      },
    );
    final session = result.data;
    if (session == null || session.id <= 0) {
      throw const FormatException('聊天会话创建失败');
    }
    return session;
  }

  Future<ChatPage<ChatRecord>> fetchRecords(int sessionId) async {
    final result = await _apiClient.getApi<ChatPage<ChatRecord>>(
      '/app/help/chat/records',
      queryParameters: {'session_id': sessionId, 'page_size': 100},
      decode: (value) => ChatPage.fromJson(value, ChatRecord.fromJson),
    );
    return result.data ??
        const ChatPage(list: [], total: 0, page: 1, pageSize: 100);
  }

  Future<ChatRecord> saveUserRecord({
    required int sessionId,
    required String content,
    String contentType = 'text',
  }) async {
    final result = await _apiClient.postApi<ChatRecord>(
      '/app/help/chat/record',
      data: {
        'session_id': sessionId,
        'content': content,
        'content_type': contentType,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return ChatRecord.fromJson(value);
        }
        throw const FormatException('Unexpected chat record shape');
      },
    );
    final record = result.data;
    if (record == null || record.id <= 0) {
      throw const FormatException('聊天消息保存失败');
    }
    return record;
  }

  Future<ChatSendResult> sendMessage({
    required int sessionId,
    required String chatMode,
    required String content,
  }) async {
    final result = await _apiClient.postApi<ChatSendResult>(
      '/app/help/chat/send',
      data: {
        'session_id': sessionId,
        'chat_mode': chatMode,
        'content': content,
      },
      options: Options(receiveTimeout: const Duration(seconds: 75)),
      decode: ChatSendResult.fromJson,
    );
    final sendResult = result.data;
    if (sendResult == null || sendResult.assistantRecord.id <= 0) {
      throw const FormatException('AI 回复保存失败');
    }
    return sendResult;
  }

  Stream<ChatStreamEvent> sendMessageStream({
    required int sessionId,
    required String chatMode,
    required String content,
  }) async* {
    final response = await _apiClient.dio.post<ResponseBody>(
      '/app/help/chat/send/stream',
      data: {
        'session_id': sessionId,
        'chat_mode': chatMode,
        'content': content,
      },
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 2),
        headers: const {'Accept': 'text/event-stream'},
      ),
    );
    final body = response.data;
    if (body == null) {
      throw const FormatException('聊天流响应为空');
    }

    final dataLines = <String>[];
    final lines = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
        continue;
      }
      if (line.isEmpty && dataLines.isNotEmpty) {
        yield ChatStreamEvent.fromJson(jsonDecode(dataLines.join('\n')));
        dataLines.clear();
      }
    }
    if (dataLines.isNotEmpty) {
      yield ChatStreamEvent.fromJson(jsonDecode(dataLines.join('\n')));
    }
  }

  Future<void> deleteSession(int sessionId) async {
    await _apiClient.postApi<bool>(
      '/app/help/chat/session/delete',
      data: {'id': sessionId},
      decode: (_) => true,
    );
  }
}

List<T> _decodeList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) decode,
) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map(decode)
      .toList(growable: false);
}
