import 'dart:convert';

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
    required this.onlineConfigId,
    required this.tempSave,
    required this.robotProfile,
    required this.sessionCount,
    this.latestSession,
  });

  final String chatMode;
  final String promptText;
  final int onlineConfigId;
  final String tempSave;
  final AiRobotProfile robotProfile;
  final int sessionCount;
  final ChatSession? latestSession;

  factory ChatModeInfo.fromJson(Map<String, dynamic> json) {
    final chatMode = (json['chat_mode'] as String?) ?? '';
    return ChatModeInfo(
      chatMode: chatMode,
      promptText: (json['prompt_text'] as String?) ?? '',
      onlineConfigId: (json['online_config_id'] as num?)?.toInt() ?? 0,
      tempSave: (json['temp_save'] ?? '').toString(),
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
    required this.onlineConfigId,
  });

  final int id;
  final String chatMode;
  final String promptText;
  final int onlineConfigId;

  int get selectedOnlineModelId => onlineConfigId;

  factory ChatConfig.fromJson(Map<String, dynamic> json) {
    return ChatConfig(
      id: (json['id'] as num?)?.toInt() ?? 0,
      chatMode: (json['chat_mode'] as String?) ?? '',
      promptText: (json['prompt_text'] as String?) ?? '',
      onlineConfigId: (json['online_config_id'] as num?)?.toInt() ?? 0,
    );
  }
}

class OnlineChatModel {
  const OnlineChatModel({
    required this.id,
    required this.name,
    required this.type,
    required this.model,
    required this.isDefault,
    required this.tempSave,
  });

  final int id;
  final String name;
  final String type;
  final String model;
  final bool isDefault;
  final String tempSave;

  String get displayName => name.trim().isNotEmpty ? name : model;

  factory OnlineChatModel.fromJson(Map<String, dynamic> json) {
    return OnlineChatModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      tempSave: (json['temp_save'] ?? '').toString(),
    );
  }
}

class ChatRealtimeConfig {
  const ChatRealtimeConfig({
    required this.wsUrl,
    required this.defaultModel,
    required this.defaultSession,
    required this.configId,
  });

  final String wsUrl;
  final String defaultModel;
  final Map<String, dynamic> defaultSession;
  final int configId;

  factory ChatRealtimeConfig.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected realtime config shape');
    }

    final session = value['default_session'];
    return ChatRealtimeConfig(
      wsUrl: (value['ws_url'] ?? '').toString(),
      defaultModel: (value['default_model'] ?? '').toString(),
      defaultSession: session is Map<String, dynamic>
          ? Map<String, dynamic>.from(session)
          : const <String, dynamic>{},
      configId: (value['config_id'] as num?)?.toInt() ?? 0,
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
    this.mediaUrl = '',
    this.mediaMimeType = '',
    this.durationSeconds = 0,
    this.transcript = '',
    this.audioUrl = '',
    this.speechStatus = '',
    this.planTasks = const [],
    this.messageTime,
  });

  final int id;
  final int sessionId;
  final String chatMode;
  final String role;
  final String content;
  final String contentType;
  final String mediaUrl;
  final String mediaMimeType;
  final int durationSeconds;
  final String transcript;
  final String audioUrl;
  final String speechStatus;
  final List<ChatPlanTaskSuggestion> planTasks;
  final String? messageTime;

  bool get isUser => role == 'user';

  ChatRecord copyWith({
    int? id,
    int? sessionId,
    String? chatMode,
    String? role,
    String? content,
    String? contentType,
    String? mediaUrl,
    String? mediaMimeType,
    int? durationSeconds,
    String? transcript,
    String? audioUrl,
    String? speechStatus,
    List<ChatPlanTaskSuggestion>? planTasks,
    String? messageTime,
  }) {
    return ChatRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      chatMode: chatMode ?? this.chatMode,
      role: role ?? this.role,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaMimeType: mediaMimeType ?? this.mediaMimeType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      transcript: transcript ?? this.transcript,
      audioUrl: audioUrl ?? this.audioUrl,
      speechStatus: speechStatus ?? this.speechStatus,
      planTasks: planTasks ?? this.planTasks,
      messageTime: messageTime ?? this.messageTime,
    );
  }

  factory ChatRecord.fromJson(Map<String, dynamic> json) {
    final ext = _decodeExt(json['ext']);
    return ChatRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      sessionId: (json['session_id'] as num?)?.toInt() ?? 0,
      chatMode: (json['chat_mode'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'user',
      content: (json['content'] as String?) ?? '',
      contentType: (json['content_type'] as String?) ?? 'text',
      mediaUrl: (ext['media_url'] ?? '').toString(),
      mediaMimeType: (ext['media_mime_type'] ?? '').toString(),
      durationSeconds: (ext['duration_seconds'] as num?)?.toInt() ?? 0,
      transcript: (ext['transcript'] ?? '').toString(),
      audioUrl: (ext['audio_url'] ?? '').toString(),
      speechStatus: (ext['speech_status'] ?? '').toString(),
      planTasks: _list(ext['plan_tasks'], ChatPlanTaskSuggestion.fromJson),
      messageTime: json['message_time'] as String?,
    );
  }
}

class ChatMediaUpload {
  const ChatMediaUpload({
    required this.attachmentId,
    required this.mediaType,
    required this.url,
    required this.mimeType,
    required this.sizeByte,
  });

  final int attachmentId;
  final String mediaType;
  final String url;
  final String mimeType;
  final int sizeByte;

  factory ChatMediaUpload.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected chat media upload shape');
    }
    return ChatMediaUpload(
      attachmentId: (value['attachment_id'] as num?)?.toInt() ?? 0,
      mediaType: (value['media_type'] ?? '').toString(),
      url: (value['url'] ?? '').toString(),
      mimeType: (value['mime_type'] ?? '').toString(),
      sizeByte: (value['size_byte'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatPlanTaskSuggestion {
  const ChatPlanTaskSuggestion({
    required this.title,
    required this.description,
    required this.taskType,
    required this.pointsReward,
    required this.requiresFeedback,
    required this.feedbackPrompt,
    required this.dailyTaskId,
  });

  final String title;
  final String description;
  final String taskType;
  final int pointsReward;
  final bool requiresFeedback;
  final String feedbackPrompt;
  final int dailyTaskId;

  bool get isAssigned => dailyTaskId > 0;

  factory ChatPlanTaskSuggestion.fromJson(Map<String, dynamic> json) {
    return ChatPlanTaskSuggestion(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      taskType: (json['task_type'] ?? 'daily').toString(),
      pointsReward: (json['points_reward'] as num?)?.toInt() ?? 10,
      requiresFeedback:
          json['requires_feedback'] == true ||
          (json['requires_feedback'] as num?)?.toInt() == 1,
      feedbackPrompt: (json['feedback_prompt'] ?? '').toString(),
      dailyTaskId: (json['daily_task_id'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatStreamEvent {
  const ChatStreamEvent({
    required this.type,
    this.session,
    this.userRecord,
    this.assistantRecord,
    this.records = const [],
    this.content = '',
    this.message = '',
  });

  final String type;
  final ChatSession? session;
  final ChatRecord? userRecord;
  final ChatRecord? assistantRecord;
  final List<ChatRecord> records;
  final String content;
  final String message;

  factory ChatStreamEvent.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected chat stream event shape');
    }

    final data = _map(value['data']);
    final type = (value['type'] ?? '').toString();
    return ChatStreamEvent(
      type: type,
      session: data['session'] is Map<String, dynamic>
          ? ChatSession.fromJson(_map(data['session']))
          : null,
      userRecord: data['user_record'] is Map<String, dynamic>
          ? ChatRecord.fromJson(_map(data['user_record']))
          : null,
      assistantRecord: data['assistant_record'] is Map<String, dynamic>
          ? ChatRecord.fromJson(_map(data['assistant_record']))
          : null,
      records: _list(data['records'], ChatRecord.fromJson),
      content: (data['content'] ?? '').toString(),
      message: (data['message'] ?? value['message'] ?? '').toString(),
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

Map<String, dynamic> _decodeExt(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      return const {};
    }
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
    'ai_doctor' => zh ? 'AI 医生' : 'AI clinician',
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
    'ai_doctor' =>
      zh
          ? '帮助整理健康问题、症状和就诊准备的 AI 助手'
          : 'An AI assistant for organizing health concerns, symptoms, and visit preparation',
    _ => zh ? '稳定、耐心的陪伴式支持助手' : 'Steady and patient companion support',
  };
}
