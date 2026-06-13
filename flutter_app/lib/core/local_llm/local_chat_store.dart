import 'dart:convert';

import '../auth/token_storage.dart';

class LocalChatMessage {
  const LocalChatMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String role;
  final String content;
  final DateTime createdAt;

  factory LocalChatMessage.fromJson(Map<String, dynamic> json) {
    return LocalChatMessage(
      role: (json['role'] as String?) ?? 'user',
      content: (json['content'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class LocalChatStore {
  const LocalChatStore(this._storage);

  final SecureTokenStorage _storage;

  Future<List<LocalChatMessage>> readMessages({
    required String memberId,
    required int modelId,
    required String chatMode,
  }) async {
    final raw = await _storage.readValue(_key(memberId, modelId, chatMode));
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LocalChatMessage.fromJson)
          .where((message) => message.content.trim().isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      await clearMessages(
        memberId: memberId,
        modelId: modelId,
        chatMode: chatMode,
      );
      return const [];
    }
  }

  Future<void> appendPair({
    required String memberId,
    required int modelId,
    required String chatMode,
    required String userContent,
    required String assistantContent,
  }) async {
    final messages = await readMessages(
      memberId: memberId,
      modelId: modelId,
      chatMode: chatMode,
    );
    final now = DateTime.now();
    final next = [
      ...messages,
      LocalChatMessage(role: 'user', content: userContent, createdAt: now),
      LocalChatMessage(
        role: 'assistant',
        content: assistantContent,
        createdAt: now,
      ),
    ];

    await _storage.writeValue(
      _key(memberId, modelId, chatMode),
      jsonEncode(next.map((message) => message.toJson()).toList()),
    );
  }

  Future<void> clearMessages({
    required String memberId,
    required int modelId,
    required String chatMode,
  }) {
    return _storage.deleteValue(_key(memberId, modelId, chatMode));
  }

  String _key(String memberId, int modelId, String chatMode) {
    return 'helpsupport.local_chat.${_safePart(memberId)}.$modelId.$chatMode';
  }

  String _safePart(String value) {
    final normalized = value.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]+'),
      '_',
    );
    return normalized.isEmpty ? 'anonymous' : normalized;
  }
}
