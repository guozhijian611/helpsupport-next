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

  Future<ChatSession> createSession(String chatMode) async {
    final result = await _apiClient.postApi<ChatSession>(
      '/app/help/chat/session',
      data: {'chat_mode': chatMode, 'is_pinned': 2},
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
  }) async {
    final result = await _apiClient.postApi<ChatRecord>(
      '/app/help/chat/record',
      data: {
        'session_id': sessionId,
        'content': content,
        'content_type': 'text',
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
}
