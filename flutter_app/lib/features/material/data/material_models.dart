enum MaterialLibrarySource { browse, history, collections }

class MaterialCategoriesQuery {
  const MaterialCategoriesQuery({required this.type, required this.locale});

  final String type;
  final String locale;

  @override
  bool operator ==(Object other) {
    return other is MaterialCategoriesQuery &&
        other.type == type &&
        other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(type, locale);
}

class MaterialCategory {
  const MaterialCategory({
    required this.id,
    required this.parentId,
    required this.name,
    required this.type,
    required this.icon,
    required this.sort,
  });

  final int id;
  final int parentId;
  final String name;
  final String type;
  final String icon;
  final int sort;

  factory MaterialCategory.fromJson(Map<String, dynamic> json) {
    return MaterialCategory(
      id: _intValue(json['id']),
      parentId: _intValue(json['parent_id']),
      name: _stringValue(json['name']),
      type: _stringValue(json['type'], fallback: 'education'),
      icon: _stringValue(json['icon']),
      sort: _intValue(json['sort'], fallback: 100),
    );
  }
}

class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.memberId,
    required this.categoryId,
    required this.mediaType,
    required this.materialType,
    required this.title,
    required this.summary,
    required this.artist,
    required this.album,
    required this.coverUrl,
    required this.contentUrl,
    required this.lyricUrl,
    required this.contentText,
    required this.tags,
    required this.durationSeconds,
    required this.isPublic,
    required this.isRecommended,
    required this.viewCount,
    required this.likeCount,
    required this.collectCount,
    required this.commentCount,
    required this.createTime,
    required this.isLiked,
    required this.isCollected,
    required this.historyProgress,
    required this.historyDurationSeconds,
    required this.comments,
  });

  final int id;
  final int memberId;
  final int categoryId;
  final String mediaType;
  final String materialType;
  final String title;
  final String summary;
  final String artist;
  final String album;
  final String coverUrl;
  final String contentUrl;
  final String lyricUrl;
  final String contentText;
  final List<String> tags;
  final int durationSeconds;
  final bool isPublic;
  final bool isRecommended;
  final int viewCount;
  final int likeCount;
  final int collectCount;
  final int commentCount;
  final String createTime;
  final bool isLiked;
  final bool isCollected;
  final double historyProgress;
  final int historyDurationSeconds;
  final List<MaterialComment> comments;

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: _intValue(json['id']),
      memberId: _intValue(json['member_id']),
      categoryId: _intValue(json['category_id']),
      mediaType: _stringValue(json['media_type'], fallback: 'article'),
      materialType: _stringValue(json['material_type'], fallback: 'education'),
      title: _stringValue(json['title']),
      summary: _stringValue(json['summary']),
      artist: _stringValue(json['artist']),
      album: _stringValue(json['album']),
      coverUrl: _stringValue(json['cover_url']),
      contentUrl: _stringValue(json['content_url']),
      lyricUrl: _stringValue(json['lyric_url']),
      contentText: _stringValue(json['content_text']),
      tags: _stringList(json['tags']),
      durationSeconds: _intValue(json['duration_seconds']),
      isPublic: _boolValue(json['is_public'], trueValue: 1),
      isRecommended: _boolValue(json['is_recommended'], trueValue: 1),
      viewCount: _intValue(json['view_count']),
      likeCount: _intValue(json['like_count']),
      collectCount: _intValue(json['collect_count']),
      commentCount: _intValue(json['comment_count']),
      createTime: _stringValue(json['create_time']),
      isLiked: _boolValue(json['is_liked']),
      isCollected: _boolValue(json['is_collected']),
      historyProgress: _doubleValue(json['history_progress']),
      historyDurationSeconds: _intValue(json['history_duration_seconds']),
      comments: _commentList(json['comments']),
    );
  }
}

class MaterialComment {
  const MaterialComment({
    required this.id,
    required this.materialId,
    required this.memberId,
    required this.parentId,
    required this.content,
    required this.attachments,
    required this.likeCount,
    required this.createTime,
    required this.authorName,
    required this.authorAvatar,
    required this.isLiked,
  });

  final int id;
  final int materialId;
  final int memberId;
  final int parentId;
  final String content;
  final List<String> attachments;
  final int likeCount;
  final String createTime;
  final String authorName;
  final String authorAvatar;
  final bool isLiked;

  factory MaterialComment.fromJson(Map<String, dynamic> json) {
    return MaterialComment(
      id: _intValue(json['id']),
      materialId: _intValue(json['material_id']),
      memberId: _intValue(json['member_id']),
      parentId: _intValue(json['parent_id']),
      content: _stringValue(json['content']),
      attachments: _stringList(json['attachments']),
      likeCount: _intValue(json['like_count']),
      createTime: _stringValue(json['create_time']),
      authorName: _stringValue(json['author_name'], fallback: 'Member'),
      authorAvatar: _stringValue(json['author_avatar']),
      isLiked: _boolValue(json['is_liked']),
    );
  }
}

class MaterialHistoryEntry {
  const MaterialHistoryEntry({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.title,
    required this.route,
    required this.authorName,
    required this.progress,
    required this.durationSeconds,
    required this.viewedAt,
  });

  final int id;
  final int contentId;
  final String contentType;
  final String title;
  final String route;
  final String authorName;
  final double progress;
  final int durationSeconds;
  final String viewedAt;

  factory MaterialHistoryEntry.fromJson(Map<String, dynamic> json) {
    return MaterialHistoryEntry(
      id: _intValue(json['id']),
      contentId: _intValue(json['content_id']),
      contentType: _stringValue(json['content_type'], fallback: 'material'),
      title: _stringValue(json['title']),
      route: _stringValue(json['route']),
      authorName: _stringValue(json['author_name']),
      progress: _doubleValue(json['progress']),
      durationSeconds: _intValue(json['duration_seconds']),
      viewedAt: _stringValue(json['viewed_at']),
    );
  }
}

class MaterialPage<T> {
  const MaterialPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> list;
  final int total;
  final int page;
  final int pageSize;

  factory MaterialPage.fromJson(
    Object? value,
    T Function(Map<String, dynamic> json) decode,
  ) {
    if (value is! Map<String, dynamic>) {
      return const MaterialPage(list: [], total: 0, page: 1, pageSize: 20);
    }

    return MaterialPage<T>(
      list: _dynamicList(value['list'], decode),
      total: _intValue(value['total']),
      page: _intValue(value['page'], fallback: 1),
      pageSize: _intValue(value['page_size'], fallback: 20),
    );
  }
}

class MaterialListQuery {
  const MaterialListQuery({
    required this.materialType,
    required this.categoryId,
    required this.keyword,
    this.mediaType = '',
    this.locale = '',
    this.page = 1,
    this.pageSize = 20,
  });

  final String materialType;
  final int categoryId;
  final String keyword;
  final String mediaType;
  final String locale;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is MaterialListQuery &&
        other.materialType == materialType &&
        other.categoryId == categoryId &&
        other.keyword == keyword &&
        other.mediaType == mediaType &&
        other.locale == locale &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
    materialType,
    categoryId,
    keyword,
    mediaType,
    locale,
    page,
    pageSize,
  );
}

class MaterialHistoryQuery {
  const MaterialHistoryQuery({this.page = 1, this.pageSize = 20});

  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is MaterialHistoryQuery &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(page, pageSize);
}

class MaterialDetailQuery {
  const MaterialDetailQuery({required this.id, required this.locale});

  final int id;
  final String locale;

  @override
  bool operator ==(Object other) {
    return other is MaterialDetailQuery &&
        other.id == id &&
        other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(id, locale);
}

class MaterialUploadResult {
  const MaterialUploadResult({
    required this.url,
    required this.originName,
    required this.mimeType,
    required this.suffix,
    required this.sizeByte,
  });

  final String url;
  final String originName;
  final String mimeType;
  final String suffix;
  final int sizeByte;

  factory MaterialUploadResult.fromJson(Map<String, dynamic> json) {
    return MaterialUploadResult(
      url: _stringValue(json['url']),
      originName: _stringValue(json['origin_name']),
      mimeType: _stringValue(json['mime_type']),
      suffix: _stringValue(json['suffix']),
      sizeByte: _intValue(json['size_byte']),
    );
  }
}

List<T> _dynamicList<T>(
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

List<MaterialComment> _commentList(Object? value) {
  return _dynamicList(value, MaterialComment.fromJson);
}

List<String> _stringList(Object? value) {
  if (value == null) {
    return const [];
  }
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      final decoded = _tryDecodeJsonArray(trimmed);
      if (decoded != null) {
        return decoded;
      }
    }
    return [trimmed];
  }
  return const [];
}

List<String>? _tryDecodeJsonArray(String value) {
  final normalized = value
      .replaceAll('[', '')
      .replaceAll(']', '')
      .split(',')
      .map((item) => item.trim().replaceAll('"', '').replaceAll("'", ''))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  return normalized.isEmpty ? null : normalized;
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

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

bool _boolValue(Object? value, {int trueValue = 1}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value.toInt() == trueValue;
  }
  if (value is String) {
    return value == '$trueValue' || value.toLowerCase() == 'true';
  }
  return false;
}
