import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import 'community_models.dart';

class CommunityRepository {
  const CommunityRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CommunityTag>> fetchTags() async {
    final result = await _apiClient.getApi<List<CommunityTag>>(
      '/app/help/community/tags',
      decode: (value) {
        if (value is! List) {
          return const [];
        }
        return value
            .whereType<Map<String, dynamic>>()
            .map(CommunityTag.fromJson)
            .toList(growable: false);
      },
    );
    return result.data ?? const [];
  }

  Future<CommunityPage<CommunityPost>> fetchPosts({
    int page = 1,
    int pageSize = 20,
    String? keyword,
  }) async {
    final result = await _apiClient.getApi<CommunityPage<CommunityPost>>(
      '/app/help/community/posts',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword,
      },
      decode: (value) => CommunityPage.fromJson(value, CommunityPost.fromJson),
    );
    return result.data ??
        const CommunityPage(list: [], total: 0, page: 1, pageSize: 20);
  }

  Future<CommunityPost> fetchPost(int id) async {
    final result = await _apiClient.getApi<CommunityPost>(
      '/app/help/community/post',
      queryParameters: {'id': id},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return CommunityPost.fromJson(value);
        }
        throw const FormatException('Unexpected community post shape');
      },
    );
    final post = result.data;
    if (post == null || post.id <= 0) {
      throw const FormatException('社区帖子不存在');
    }
    return post;
  }

  Future<CommunityPost> createPost({
    required String content,
    bool isAnonymous = false,
    List<String>? images,
    List<String>? tags,
    String? linkUrl,
  }) async {
    final result = await _apiClient.postApi<CommunityPost>(
      '/app/help/community/post',
      data: {
        'content': content,
        'is_anonymous': isAnonymous ? 1 : 2,
        if (images != null && images.isNotEmpty) 'images': images,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (linkUrl != null && linkUrl.trim().isNotEmpty) 'link_url': linkUrl,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return CommunityPost.fromJson(value);
        }
        throw const FormatException('Unexpected community post shape');
      },
    );
    final post = result.data;
    if (post == null || post.id <= 0) {
      throw const FormatException('社区帖子发布失败');
    }
    return post;
  }

  Future<CommunityPage<CommunityComment>> fetchComments({
    required int postId,
    int page = 1,
    int pageSize = 50,
    bool includeReplies = false,
  }) async {
    final result = await _apiClient.getApi<CommunityPage<CommunityComment>>(
      '/app/help/community/comments',
      queryParameters: {
        'post_id': postId,
        'page': page,
        'page_size': pageSize,
        if (includeReplies) 'with_replies': 1,
      },
      decode: (value) =>
          CommunityPage.fromJson(value, CommunityComment.fromJson),
    );
    return result.data ??
        const CommunityPage(list: [], total: 0, page: 1, pageSize: 50);
  }

  Future<CommunityComment> createComment({
    required int postId,
    required String content,
    bool isAnonymous = false,
    int? parentId,
    int? replyToMemberId,
    List<String>? attachments,
  }) async {
    final result = await _apiClient.postApi<CommunityComment>(
      '/app/help/community/comment',
      data: {
        'post_id': postId,
        'content': content,
        'is_anonymous': isAnonymous ? 1 : 2,
        if (parentId != null && parentId > 0) 'parent_id': parentId,
        if (replyToMemberId != null && replyToMemberId > 0)
          'reply_to_member_id': replyToMemberId,
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return CommunityComment.fromJson(value);
        }
        throw const FormatException('Unexpected community comment shape');
      },
    );
    final comment = result.data;
    if (comment == null || comment.id <= 0) {
      throw const FormatException('社区评论发布失败');
    }
    return comment;
  }

  Future<bool> togglePostLike(int postId) async {
    final result = await _apiClient.postApi<bool>(
      '/app/help/community/like',
      data: {'target_type': 1, 'target_id': postId},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value['is_liked'] == true;
        }
        return false;
      },
    );
    return result.data ?? false;
  }

  Future<bool> toggleCommentLike(int commentId) async {
    final result = await _apiClient.postApi<bool>(
      '/app/help/community/like',
      data: {'target_type': 2, 'target_id': commentId},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value['is_liked'] == true;
        }
        return false;
      },
    );
    return result.data ?? false;
  }

  Future<bool> togglePostCollect(int postId) async {
    final result = await _apiClient.postApi<bool>(
      '/app/help/community/collect',
      data: {'post_id': postId},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value['is_collected'] == true;
        }
        return false;
      },
    );
    return result.data ?? false;
  }

  Future<bool> toggleFollowTag(int tagId) async {
    final result = await _apiClient.postApi<bool>(
      '/app/help/community/follow-tag',
      data: {'tag_id': tagId},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value['is_followed'] == true;
        }
        return false;
      },
    );
    return result.data ?? false;
  }

  Future<bool> toggleFollowMember(int memberId) async {
    final result = await _apiClient.postApi<bool>(
      '/app/help/community/follow-member',
      data: {'target_member_id': memberId},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value['is_followed'] == true;
        }
        return false;
      },
    );
    return result.data ?? false;
  }

  Future<String> uploadImage({required XFile file}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    final result = await _apiClient.postApi<String>(
      '/app/help/community/upload-image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return (value['url'] ?? '').toString();
        }
        throw const FormatException('Unexpected community upload response');
      },
    );
    final url = result.data?.trim() ?? '';
    if (url.isEmpty) {
      throw const FormatException('社区图片上传失败');
    }
    return url;
  }

  Future<CommunityMemberProfile> fetchMemberProfile({int? memberId}) async {
    final result = await _apiClient.getApi<CommunityMemberProfile>(
      '/app/help/community/member/profile',
      queryParameters: {
        if (memberId != null && memberId > 0) 'member_id': memberId,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return CommunityMemberProfile.fromJson(value);
        }
        throw const FormatException('Unexpected community member profile');
      },
    );
    final profile = result.data;
    if (profile == null || profile.memberId <= 0) {
      throw const FormatException('社区成员主页不存在');
    }
    return profile;
  }

  Future<CommunityPage<CommunityPost>> fetchMemberPosts({
    required int memberId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _apiClient.getApi<CommunityPage<CommunityPost>>(
      '/app/help/community/member/posts',
      queryParameters: {
        'member_id': memberId,
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) => CommunityPage.fromJson(value, CommunityPost.fromJson),
    );
    return result.data ??
        const CommunityPage(list: [], total: 0, page: 1, pageSize: 20);
  }

  Future<CommunityPage<CommunityMember>> fetchFollowingMembers({
    int? memberId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final result = await _apiClient.getApi<CommunityPage<CommunityMember>>(
      '/app/help/community/member/following',
      queryParameters: {
        if (memberId != null && memberId > 0) 'member_id': memberId,
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) =>
          CommunityPage.fromJson(value, CommunityMember.fromJson),
    );
    return result.data ??
        const CommunityPage(list: [], total: 0, page: 1, pageSize: 50);
  }

  Future<CommunityPage<CommunityMember>> fetchFollowerMembers({
    int? memberId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final result = await _apiClient.getApi<CommunityPage<CommunityMember>>(
      '/app/help/community/member/followers',
      queryParameters: {
        if (memberId != null && memberId > 0) 'member_id': memberId,
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) =>
          CommunityPage.fromJson(value, CommunityMember.fromJson),
    );
    return result.data ??
        const CommunityPage(list: [], total: 0, page: 1, pageSize: 50);
  }

  Future<CommunityPage<CommunityPost>> fetchReviewPosts({
    String scope = 'pending',
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _apiClient.getApi<CommunityPage<CommunityPost>>(
      '/app/help/community/review/posts',
      queryParameters: {
        'scope': scope,
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword,
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) => CommunityPage.fromJson(value, CommunityPost.fromJson),
    );
    return result.data ??
        const CommunityPage(list: [], total: 0, page: 1, pageSize: 20);
  }

  Future<CommunityPost> reviewPost({
    required int postId,
    required int auditStatus,
    String? auditRemark,
  }) async {
    final result = await _apiClient.postApi<CommunityPost>(
      '/app/help/community/review/post',
      data: {
        'post_id': postId,
        'audit_status': auditStatus,
        if (auditRemark != null && auditRemark.trim().isNotEmpty)
          'audit_remark': auditRemark.trim(),
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return CommunityPost.fromJson(value);
        }
        throw const FormatException('Unexpected community review post');
      },
    );
    final post = result.data;
    if (post == null || post.id <= 0) {
      throw const FormatException('社区帖子审核失败');
    }
    return post;
  }
}
