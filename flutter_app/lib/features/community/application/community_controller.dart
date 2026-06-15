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
          .fetchComments(postId: postId, includeReplies: true);
    });

final communityMemberProfileProvider = FutureProvider.autoDispose
    .family<CommunityMemberProfile, int>((ref, memberId) {
      return ref
          .watch(communityRepositoryProvider)
          .fetchMemberProfile(memberId: memberId > 0 ? memberId : null);
    });

final communityMemberPostsProvider = FutureProvider.autoDispose
    .family<CommunityPage<CommunityPost>, int>((ref, memberId) {
      return ref
          .watch(communityRepositoryProvider)
          .fetchMemberPosts(memberId: memberId);
    });

final communityFollowingProvider = FutureProvider.autoDispose
    .family<CommunityPage<CommunityMember>, int>((ref, memberId) {
      return ref
          .watch(communityRepositoryProvider)
          .fetchFollowingMembers(memberId: memberId > 0 ? memberId : null);
    });

final communityFollowersProvider = FutureProvider.autoDispose
    .family<CommunityPage<CommunityMember>, int>((ref, memberId) {
      return ref
          .watch(communityRepositoryProvider)
          .fetchFollowerMembers(memberId: memberId > 0 ? memberId : null);
    });

final communityReviewPostsProvider = FutureProvider.autoDispose
    .family<CommunityPage<CommunityPost>, String>((ref, scope) {
      return ref
          .watch(communityRepositoryProvider)
          .fetchReviewPosts(scope: scope);
    });
