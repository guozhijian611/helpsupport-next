class ChatOverview {
  const ChatOverview({required this.modes, required this.recentSessions});

  final List<ChatModeInfo> modes;
  final List<ChatSession> recentSessions;

  factory ChatOverview.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const ChatOverview(modes: [], recentSessions: []);
    }

    return ChatOverview(
      modes: _list(value['modes'], ChatModeInfo.fromJson),
      recentSessions: _list(value['recent_sessions'], ChatSession.fromJson),
    );
  }
}

class ChatModeInfo {
  const ChatModeInfo({
    required this.chatMode,
    required this.promptText,
    required this.sessionCount,
    this.latestSession,
  });

  final String chatMode;
  final String promptText;
  final int sessionCount;
  final ChatSession? latestSession;

  factory ChatModeInfo.fromJson(Map<String, dynamic> json) {
    return ChatModeInfo(
      chatMode: (json['chat_mode'] as String?) ?? '',
      promptText: (json['prompt_text'] as String?) ?? '',
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      latestSession: json['latest_session'] is Map<String, dynamic>
          ? ChatSession.fromJson(json['latest_session'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.chatMode,
    required this.sessionName,
    required this.lastMessage,
    this.lastMessageTime,
    required this.isPinned,
  });

  final int id;
  final String chatMode;
  final String sessionName;
  final String lastMessage;
  final String? lastMessageTime;
  final bool isPinned;

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: (json['id'] as num?)?.toInt() ?? 0,
      chatMode: (json['chat_mode'] as String?) ?? '',
      sessionName: (json['session_name'] as String?) ?? '',
      lastMessage: (json['last_message'] as String?) ?? '',
      lastMessageTime: json['last_message_time'] as String?,
      isPinned: ((json['is_pinned'] as num?)?.toInt() ?? 2) == 1,
    );
  }
}

class ChatConfig {
  const ChatConfig({
    required this.id,
    required this.chatMode,
    required this.promptText,
  });

  final int id;
  final String chatMode;
  final String promptText;

  factory ChatConfig.fromJson(Map<String, dynamic> json) {
    return ChatConfig(
      id: (json['id'] as num?)?.toInt() ?? 0,
      chatMode: (json['chat_mode'] as String?) ?? '',
      promptText: (json['prompt_text'] as String?) ?? '',
    );
  }
}

class ChatRecord {
  const ChatRecord({
    required this.id,
    required this.sessionId,
    required this.chatMode,
    required this.role,
    required this.content,
    required this.contentType,
    this.messageTime,
  });

  final int id;
  final int sessionId;
  final String chatMode;
  final String role;
  final String content;
  final String contentType;
  final String? messageTime;

  bool get isUser => role == 'user';

  factory ChatRecord.fromJson(Map<String, dynamic> json) {
    return ChatRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      sessionId: (json['session_id'] as num?)?.toInt() ?? 0,
      chatMode: (json['chat_mode'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'user',
      content: (json['content'] as String?) ?? '',
      contentType: (json['content_type'] as String?) ?? 'text',
      messageTime: json['message_time'] as String?,
    );
  }
}

class ChatSendResult {
  const ChatSendResult({
    required this.session,
    required this.userRecord,
    required this.assistantRecord,
    required this.records,
  });

  final ChatSession session;
  final ChatRecord userRecord;
  final ChatRecord assistantRecord;
  final List<ChatRecord> records;

  factory ChatSendResult.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected chat send result shape');
    }

    return ChatSendResult(
      session: ChatSession.fromJson(_map(value['session'])),
      userRecord: ChatRecord.fromJson(_map(value['user_record'])),
      assistantRecord: ChatRecord.fromJson(_map(value['assistant_record'])),
      records: _list(value['records'], ChatRecord.fromJson),
    );
  }
}

class ChatPage<T> {
  const ChatPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> list;
  final int total;
  final int page;
  final int pageSize;

  factory ChatPage.fromJson(
    Object? value,
    T Function(Map<String, dynamic> json) decode,
  ) {
    if (value is! Map<String, dynamic>) {
      return const ChatPage(list: [], total: 0, page: 1, pageSize: 20);
    }

    return ChatPage<T>(
      list: _list(value['list'], decode),
      total: (value['total'] as num?)?.toInt() ?? 0,
      page: (value['page'] as num?)?.toInt() ?? 1,
      pageSize: (value['page_size'] as num?)?.toInt() ?? 20,
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return const {};
}

List<T> _list<T>(Object? value, T Function(Map<String, dynamic> json) decode) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(decode)
      .toList(growable: false);
}
