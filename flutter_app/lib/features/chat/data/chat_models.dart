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
    required this.robotProfile,
    required this.sessionCount,
    this.latestSession,
  });

  final String chatMode;
  final String promptText;
  final AiRobotProfile robotProfile;
  final int sessionCount;
  final ChatSession? latestSession;

  factory ChatModeInfo.fromJson(Map<String, dynamic> json) {
    final chatMode = (json['chat_mode'] as String?) ?? '';
    return ChatModeInfo(
      chatMode: chatMode,
      promptText: (json['prompt_text'] as String?) ?? '',
      robotProfile: AiRobotProfile.fromJson(
        _map(json['robot_profile']),
        fallbackChatMode: chatMode,
        fallbackRuntimeMode: 'online',
      ),
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      latestSession: json['latest_session'] is Map<String, dynamic>
          ? ChatSession.fromJson(json['latest_session'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AiRobotProfile {
  const AiRobotProfile({
    required this.id,
    required this.chatMode,
    required this.runtimeMode,
    required this.displayName,
    required this.displayNameEn,
    required this.description,
    required this.descriptionEn,
    required this.avatar,
    required this.darkAvatar,
  });

  final int id;
  final String chatMode;
  final String runtimeMode;
  final String displayName;
  final String displayNameEn;
  final String description;
  final String descriptionEn;
  final String avatar;
  final String darkAvatar;

  String displayNameFor(String languageCode) {
    if (languageCode == 'zh') {
      return displayName.trim().isNotEmpty
          ? displayName
          : _fallbackDisplayName(chatMode, true);
    }
    return displayNameEn.trim().isNotEmpty
        ? displayNameEn
        : _fallbackDisplayName(chatMode, false);
  }

  String descriptionFor(String languageCode) {
    if (languageCode == 'zh') {
      return description.trim().isNotEmpty
          ? description
          : _fallbackDescription(chatMode, true);
    }
    return descriptionEn.trim().isNotEmpty
        ? descriptionEn
        : _fallbackDescription(chatMode, false);
  }

  String avatarFor({required bool darkMode}) {
    if (darkMode && darkAvatar.trim().isNotEmpty) {
      return darkAvatar;
    }
    return avatar;
  }

  factory AiRobotProfile.fromJson(
    Map<String, dynamic> json, {
    String fallbackChatMode = 'companion',
    String fallbackRuntimeMode = 'online',
  }) {
    final chatMode = (json['chat_mode'] as String?) ?? fallbackChatMode;
    return AiRobotProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      chatMode: chatMode,
      runtimeMode: (json['runtime_mode'] as String?) ?? fallbackRuntimeMode,
      displayName:
          (json['display_name'] as String?) ??
          _fallbackDisplayName(chatMode, true),
      displayNameEn:
          (json['display_name_en'] as String?) ??
          _fallbackDisplayName(chatMode, false),
      description:
          (json['description'] as String?) ??
          _fallbackDescription(chatMode, true),
      descriptionEn:
          (json['description_en'] as String?) ??
          _fallbackDescription(chatMode, false),
      avatar: (json['avatar'] as String?) ?? '',
      darkAvatar: (json['dark_avatar'] as String?) ?? '',
    );
  }

  factory AiRobotProfile.fallback({
    required String chatMode,
    required String runtimeMode,
  }) {
    return AiRobotProfile(
      id: 0,
      chatMode: chatMode,
      runtimeMode: runtimeMode,
      displayName: _fallbackDisplayName(chatMode, true),
      displayNameEn: _fallbackDisplayName(chatMode, false),
      description: _fallbackDescription(chatMode, true),
      descriptionEn: _fallbackDescription(chatMode, false),
      avatar: '',
      darkAvatar: '',
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

String _fallbackDisplayName(String mode, bool zh) {
  return switch (mode) {
    'doctor' => zh ? 'AI 心理医生' : 'AI doctor',
    'patient' => zh ? 'AI 模拟病人' : 'AI patient',
    _ => zh ? 'AI 心理陪伴' : 'AI companion',
  };
}

String _fallbackDescription(String mode, bool zh) {
  return switch (mode) {
    'doctor' =>
      zh ? '谨慎、温和的心理支持助手' : 'Careful and gentle mental health support',
    'patient' =>
      zh
          ? '用于角色演练和沟通练习的模拟病人'
          : 'A simulated patient for role-play and communication practice',
    _ => zh ? '稳定、耐心的陪伴式支持助手' : 'Steady and patient companion support',
  };
}
