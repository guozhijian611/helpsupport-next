enum AuthProtocolType {
  privacy('privacy', 2),
  terms('terms', 4);

  const AuthProtocolType(this.routeValue, this.code);

  final String routeValue;
  final int code;

  static AuthProtocolType? fromRouteValue(String value) {
    for (final type in values) {
      if (type.routeValue == value) {
        return type;
      }
    }
    return null;
  }
}

class AuthProtocolQuery {
  const AuthProtocolQuery({required this.type, required this.locale});

  final AuthProtocolType type;
  final String locale;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AuthProtocolQuery &&
        other.type == type &&
        other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(type, locale);
}

class AuthProtocolDocument {
  const AuthProtocolDocument({
    required this.type,
    required this.locale,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  final AuthProtocolType type;
  final String locale;
  final String title;
  final String content;
  final String updatedAt;

  factory AuthProtocolDocument.fromJson(Object? value, AuthProtocolType type) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('协议响应格式错误');
    }

    return AuthProtocolDocument(
      type: type,
      locale: (value['locale'] ?? '').toString().trim(),
      title: (value['title'] ?? '').toString().trim(),
      content: (value['content'] ?? '').toString(),
      updatedAt: (value['update_time'] ?? '').toString(),
    );
  }
}
