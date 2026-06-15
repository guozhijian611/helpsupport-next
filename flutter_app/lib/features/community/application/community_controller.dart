import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/community_models.dart';
import '../data/community_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.watch(apiClientProvider));
});

final communityTagsProvider = FutureProvider.autoDispose<List<CommunityTag>>((
  ref,
) {
  return ref.watch(communityRepositoryProvider).fetchTags();
});

final communityPostsProvider =
    FutureProvider.autoDispose<CommunityPage<CommunityPost>>((ref) {
      return ref.watch(communityRepositoryProvider).fetchPosts();
    });

final communityPostsSearchProvider = FutureProvider.autoDispose
    .family<CommunityPage<CommunityPost>, String>((ref, keyword) {
      return ref
          .watch(communityRepositoryProvider)
          .fetchPosts(keyword: keyword);
    });

final communityPostProvider = FutureProvider.autoDispose
    .family<CommunityPost, int>((ref, postId) {
      return ref.watch(communityRepositoryProvider).fetchPost(postId);
    });

final communityCommentsProvider = FutureProvider.autoDispose
    .family<CommunityPage<CommunityComment>, int>((ref, postId) {
      return ref
          .watch(communityRepositoryProvider)
          .fetchComments(postId: postId);
    });
