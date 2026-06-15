import 'dart:convert';

class MessagePage<T> {
  const MessagePage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> list;
  final int total;
  final int page;
  final int pageSize;

  factory MessagePage.fromJson(
    Object? value,
    T Function(Map<String, dynamic> json) decode,
  ) {
    if (value is! Map<String, dynamic>) {
      return const MessagePage(list: [], total: 0, page: 1, pageSize: 20);
    }

    return MessagePage<T>(
      list: _list(value['list'], decode),
      total: _intValue(value['total']),
      page: _intValue(value['page'], fallback: 1),
      pageSize: _intValue(value['page_size'], fallback: 20),
    );
  }
}

class MessageItem {
  const MessageItem({
    required this.id,
    required this.messageType,
    required this.title,
    required this.content,
    required this.bizType,
    required this.bizId,
    required this.route,
    required this.isRead,
    required this.createTime,
    required this.ext,
  });

  final int id;
  final int messageType;
  final String title;
  final String content;
  final String bizType;
  final int bizId;
  final String route;
  final int isRead;
  final String createTime;
  final Map<String, dynamic> ext;

  bool get unread => isRead != 1;

  Map<String, dynamic> get payload {
    final value = ext['payload'];
    if (value is Map<String, dynamic>) {
      return value;
    }
    return const <String, dynamic>{};
  }

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: _intValue(json['id']),
      messageType: _intValue(json['message_type'], fallback: 5),
      title: _stringValue(json['title'], fallback: '消息'),
      content: _stringValue(json['content']),
      bizType: _stringValue(json['biz_type']),
      bizId: _intValue(json['biz_id']),
      route: _stringValue(json['route']),
      isRead: _intValue(json['is_read'], fallback: 2),
      createTime: _stringValue(json['create_time']),
      ext: _mapValue(json['ext']),
    );
  }
}

class MessageQuery {
  const MessageQuery({this.isRead, this.page = 1, this.pageSize = 50});

  final int? isRead;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is MessageQuery &&
        other.isRead == isRead &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(isRead, page, pageSize);
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

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return const <String, dynamic>{};
    }
  }
  return const <String, dynamic>{};
}
