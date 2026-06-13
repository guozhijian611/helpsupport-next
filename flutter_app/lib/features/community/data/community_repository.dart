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
  }) async {
    final result = await _apiClient.getApi<CommunityPage<CommunityPost>>(
      '/app/help/community/posts',
      queryParameters: {'page': page, 'page_size': pageSize},
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
  }) async {
    final result = await _apiClient.postApi<CommunityPost>(
      '/app/help/community/post',
      data: {'content': content, 'is_anonymous': isAnonymous ? 1 : 2},
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
  }) async {
    final result = await _apiClient.getApi<CommunityPage<CommunityComment>>(
      '/app/help/community/comments',
      queryParameters: {'post_id': postId, 'page': page, 'page_size': pageSize},
      decode: (value) =>
          CommunityPage.fromJson(value, CommunityComment.fromJson),
    );
    return result.data ??
        const CommunityPage(list: [], total: 0, page: 1, pageSize: 50);
  }

  Future<CommunityComment> createComment({
    required int postId,
    required String content,
  }) async {
    final result = await _apiClient.postApi<CommunityComment>(
      '/app/help/community/comment',
      data: {'post_id': postId, 'content': content},
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
}
