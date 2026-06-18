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
    required this.linkUrl,
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
    this.auditRemark = '',
    required this.createTime,
    required this.isLiked,
    required this.isCollected,
    required this.isFollowedAuthor,
    required this.isMutualFollowAuthor,
  });

  final int id;
  final int memberId;
  final String content;
  final List<String> images;
  final String linkUrl;
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
  final String auditRemark;
  final String createTime;
  final bool isLiked;
  final bool isCollected;
  final bool isFollowedAuthor;
  final bool isMutualFollowAuthor;

  bool get isPendingReview => auditStatus == 0;
  CommunityStructuredText get structuredText => _splitStructuredText(content);
  String get title => structuredText.title;
  String get body => structuredText.body;
  bool get hasTitle => structuredText.hasTitle;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: _intValue(json['id']),
      memberId: _intValue(json['member_id']),
      content: _stringValue(json['content']),
      images: _stringList(json['images']),
      linkUrl: _stringValue(json['link_url']),
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
      auditRemark: _stringValue(json['audit_remark']),
      createTime: _stringValue(json['create_time']),
      isLiked: _boolValue(json['is_liked']),
      isCollected: _boolValue(json['is_collected']),
      isFollowedAuthor: _boolValue(json['is_followed_author']),
      isMutualFollowAuthor: _boolValue(json['is_mutual_follow_author']),
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.memberId,
    required this.parentId,
    required this.replyToMemberId,
    required this.replyToMemberName,
    required this.content,
    required this.attachments,
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
  final int replyToMemberId;
  final String replyToMemberName;
  final String content;
  final List<String> attachments;
  final String authorName;
  final String authorAvatar;
  final bool isAnonymous;
  final int likeCount;
  final int auditStatus;
  final String createTime;
  final bool isLiked;

  bool get isReply => parentId > 0;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: _intValue(json['id']),
      postId: _intValue(json['post_id']),
      memberId: _intValue(json['member_id']),
      parentId: _intValue(json['parent_id']),
      replyToMemberId: _intValue(json['reply_to_member_id']),
      replyToMemberName: _stringValue(json['reply_to_member_name']),
      content: _stringValue(json['content']),
      attachments: _stringList(json['attachments']),
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
    required this.isFollowed,
  });

  final int id;
  final String name;
  final String color;
  final int sort;
  final bool isFollowed;

  factory CommunityTag.fromJson(Map<String, dynamic> json) {
    return CommunityTag(
      id: _intValue(json['id']),
      name: _stringValue(json['tag_name']),
      color: _stringValue(json['color']),
      sort: _intValue(json['sort'], fallback: 100),
      isFollowed: _boolValue(json['is_followed']),
    );
  }
}

class CommunityMemberProfile {
  const CommunityMemberProfile({
    required this.memberId,
    required this.displayName,
    required this.avatar,
    required this.bio,
    required this.recoveryGoal,
    required this.memberRole,
    required this.isDoctor,
    required this.doctorTitle,
    required this.recoveryDays,
    required this.isSelf,
    required this.isFollowed,
    required this.isMutualFollow,
    required this.followCount,
    required this.followerCount,
    required this.likeCount,
    required this.postCount,
  });

  final int memberId;
  final String displayName;
  final String avatar;
  final String bio;
  final String recoveryGoal;
  final String memberRole;
  final bool isDoctor;
  final String doctorTitle;
  final int recoveryDays;
  final bool isSelf;
  final bool isFollowed;
  final bool isMutualFollow;
  final int followCount;
  final int followerCount;
  final int likeCount;
  final int postCount;

  factory CommunityMemberProfile.fromJson(Map<String, dynamic> json) {
    return CommunityMemberProfile(
      memberId: _intValue(json['member_id']),
      displayName: _stringValue(json['display_name'], fallback: 'Member'),
      avatar: _stringValue(json['avatar']),
      bio: _stringValue(json['bio']),
      recoveryGoal: _stringValue(json['recovery_goal']),
      memberRole: _stringValue(json['member_role'], fallback: 'patient'),
      isDoctor: _boolValue(json['is_doctor']),
      doctorTitle: _stringValue(json['doctor_title']),
      recoveryDays: _intValue(json['recovery_days']),
      isSelf: _boolValue(json['is_self']),
      isFollowed: _boolValue(json['is_followed']),
      isMutualFollow: _boolValue(json['is_mutual_follow']),
      followCount: _intValue(json['follow_count']),
      followerCount: _intValue(json['follower_count']),
      likeCount: _intValue(json['like_count']),
      postCount: _intValue(json['post_count']),
    );
  }
}

class CommunityMember {
  const CommunityMember({
    required this.memberId,
    required this.displayName,
    required this.avatar,
    required this.bio,
    required this.recoveryGoal,
    required this.memberRole,
    required this.isDoctor,
    required this.doctorTitle,
    required this.recoveryDays,
    required this.isSelf,
    required this.isFollowed,
    required this.isMutualFollow,
  });

  final int memberId;
  final String displayName;
  final String avatar;
  final String bio;
  final String recoveryGoal;
  final String memberRole;
  final bool isDoctor;
  final String doctorTitle;
  final int recoveryDays;
  final bool isSelf;
  final bool isFollowed;
  final bool isMutualFollow;

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    return CommunityMember(
      memberId: _intValue(json['member_id']),
      displayName: _stringValue(json['display_name'], fallback: 'Member'),
      avatar: _stringValue(json['avatar']),
      bio: _stringValue(json['bio']),
      recoveryGoal: _stringValue(json['recovery_goal']),
      memberRole: _stringValue(json['member_role'], fallback: 'patient'),
      isDoctor: _boolValue(json['is_doctor']),
      doctorTitle: _stringValue(json['doctor_title']),
      recoveryDays: _intValue(json['recovery_days']),
      isSelf: _boolValue(json['is_self']),
      isFollowed: _boolValue(json['is_followed']),
      isMutualFollow: _boolValue(json['is_mutual_follow']),
    );
  }
}

class CommunityFollowState {
  const CommunityFollowState({
    required this.isFollowed,
    required this.isMutualFollow,
  });

  final bool isFollowed;
  final bool isMutualFollow;

  factory CommunityFollowState.fromJson(Map<String, dynamic> json) {
    return CommunityFollowState(
      isFollowed: _boolValue(json['is_followed']),
      isMutualFollow: _boolValue(json['is_mutual_follow']),
    );
  }
}

class CommunityStructuredText {
  const CommunityStructuredText({required this.title, required this.body});

  final String title;
  final String body;

  bool get hasTitle => title.isNotEmpty && body.isNotEmpty;
}

CommunityStructuredText _splitStructuredText(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return const CommunityStructuredText(title: '', body: '');
  }

  final sections = normalized
      .split(RegExp(r'(?:\r?\n){2,}'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  if (sections.length >= 2 && sections.first.length <= 48) {
    return CommunityStructuredText(
      title: sections.first,
      body: sections.skip(1).join('\n\n'),
    );
  }

  final lines = normalized
      .split(RegExp(r'\r?\n'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  if (lines.length >= 2 && lines.first.length <= 48) {
    return CommunityStructuredText(
      title: lines.first,
      body: lines.skip(1).join('\n'),
    );
  }

  return CommunityStructuredText(title: '', body: normalized);
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
