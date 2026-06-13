class CommunityPage<T> {
  const CommunityPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> list;
  final int total;
  final int page;
  final int pageSize;

  factory CommunityPage.fromJson(
    Object? value,
    T Function(Map<String, dynamic> json) decode,
  ) {
    if (value is! Map<String, dynamic>) {
      return const CommunityPage(list: [], total: 0, page: 1, pageSize: 20);
    }

    return CommunityPage<T>(
      list: _list(value['list'], decode),
      total: _intValue(value['total']),
      page: _intValue(value['page'], fallback: 1),
      pageSize: _intValue(value['page_size'], fallback: 20),
    );
  }
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.memberId,
    required this.content,
    required this.images,
    required this.tags,
    required this.authorName,
    required this.authorAvatar,
    required this.isAnonymous,
    required this.isDoctorPost,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.collectCount,
    required this.isTop,
    required this.auditStatus,
    required this.createTime,
    required this.isLiked,
    required this.isCollected,
  });

  final int id;
  final int memberId;
  final String content;
  final List<String> images;
  final List<String> tags;
  final String authorName;
  final String authorAvatar;
  final bool isAnonymous;
  final bool isDoctorPost;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int collectCount;
  final bool isTop;
  final int auditStatus;
  final String createTime;
  final bool isLiked;
  final bool isCollected;

  bool get isPendingReview => auditStatus == 0;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: _intValue(json['id']),
      memberId: _intValue(json['member_id']),
      content: _stringValue(json['content']),
      images: _stringList(json['images']),
      tags: _stringList(json['tags']),
      authorName: _stringValue(json['author_name'], fallback: 'Member'),
      authorAvatar: _stringValue(json['author_avatar']),
      isAnonymous: _intValue(json['is_anonymous'], fallback: 2) == 1,
      isDoctorPost: _intValue(json['is_doctor_post'], fallback: 2) == 1,
      viewCount: _intValue(json['view_count']),
      likeCount: _intValue(json['like_count']),
      commentCount: _intValue(json['comment_count']),
      collectCount: _intValue(json['collect_count']),
      isTop: _intValue(json['is_top'], fallback: 2) == 1,
      auditStatus: _intValue(json['audit_status']),
      createTime: _stringValue(json['create_time']),
      isLiked: _boolValue(json['is_liked']),
      isCollected: _boolValue(json['is_collected']),
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.memberId,
    required this.parentId,
    required this.content,
    required this.authorName,
    required this.authorAvatar,
    required this.isAnonymous,
    required this.likeCount,
    required this.auditStatus,
    required this.createTime,
    required this.isLiked,
  });

  final int id;
  final int postId;
  final int memberId;
  final int parentId;
  final String content;
  final String authorName;
  final String authorAvatar;
  final bool isAnonymous;
  final int likeCount;
  final int auditStatus;
  final String createTime;
  final bool isLiked;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: _intValue(json['id']),
      postId: _intValue(json['post_id']),
      memberId: _intValue(json['member_id']),
      parentId: _intValue(json['parent_id']),
      content: _stringValue(json['content']),
      authorName: _stringValue(json['author_name'], fallback: 'Member'),
      authorAvatar: _stringValue(json['author_avatar']),
      isAnonymous: _intValue(json['is_anonymous'], fallback: 2) == 1,
      likeCount: _intValue(json['like_count']),
      auditStatus: _intValue(json['audit_status'], fallback: 1),
      createTime: _stringValue(json['create_time']),
      isLiked: _boolValue(json['is_liked']),
    );
  }
}

class CommunityTag {
  const CommunityTag({
    required this.id,
    required this.name,
    required this.color,
    required this.sort,
  });

  final int id;
  final String name;
  final String color;
  final int sort;

  factory CommunityTag.fromJson(Map<String, dynamic> json) {
    return CommunityTag(
      id: _intValue(json['id']),
      name: _stringValue(json['tag_name']),
      color: _stringValue(json['color']),
      sort: _intValue(json['sort'], fallback: 100),
    );
  }
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

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.map((item) => item.toString()).toList(growable: false);
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

bool _boolValue(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value.toInt() == 1;
  }
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return false;
}
