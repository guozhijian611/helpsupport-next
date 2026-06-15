import '../../../core/api/api_client.dart';
import 'message_models.dart';

class MessageRepository {
  const MessageRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<MessagePage<MessageItem>> fetchMessages({
    int? isRead,
    int page = 1,
    int pageSize = 50,
  }) async {
    final result = await _apiClient.getApi<MessagePage<MessageItem>>(
      '/app/help/me/messages',
      queryParameters: {
        if (isRead != null) 'is_read': isRead,
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) => MessagePage.fromJson(value, MessageItem.fromJson),
    );
    return result.data ??
        const MessagePage(list: [], total: 0, page: 1, pageSize: 50);
  }

  Future<int> fetchUnreadCount() async {
    final result = await _apiClient.getApi<int>(
      '/app/help/home/summary',
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return _intValue(value['unread_message_count']);
        }
        return 0;
      },
    );
    return result.data ?? 0;
  }

  Future<int> readMessage({int? messageId, bool all = false}) async {
    final result = await _apiClient.putApi<int>(
      '/app/help/me/message/read',
      data: {
        if (messageId != null && messageId > 0) 'message_id': messageId,
        if (all) 'all': 1,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return _intValue(value['affected']);
        }
        return 0;
      },
    );
    return result.data ?? 0;
  }
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}
