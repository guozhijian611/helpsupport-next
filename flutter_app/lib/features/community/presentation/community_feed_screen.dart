import 'package:flutter/material.dart';
import 'package:helpsupport_app/core/cache/cached_remote_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/ui/app_tab_shell_metrics.dart';
import '../../auth/application/auth_controller.dart';
import '../../message/application/message_controller.dart';
import '../application/community_controller.dart';
import '../data/community_models.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

enum _CommunityFeedScope { public, following, topics }

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _CommunityFeedScope _scope = _CommunityFeedScope.public;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    final metrics = AppTabShellMetrics.of(context);
    final keyword = _query.trim();
    final posts = _watchPosts(keyword);
    final tags = ref.watch(communityTagsProvider);
    final unreadCount = ref.watch(unreadMessageCountProvider);
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final apiClient = ref.watch(apiClientProvider);
    final avatarUrl = apiClient.resolveUrl(
      _firstText([session?.member['avatar'], session?.profile['avatar']]),
    );
    final badge = _badgeText(unreadCount.asData?.value ?? 0);
    final listPadding = metrics
        .edgeInsets(22, 16, 22, 0)
        .copyWith(
          bottom: metrics.floatingTabBarInset(context, extraSpacing: 20),
        );

    return ColoredBox(
      color: palette.pageBackground,
      child: Column(
        children: [
          Padding(
            padding: metrics.edgeInsets(22, 18, 22, 0),
            child: _CommunityTopBar(
              avatarUrl: avatarUrl,
              badge: badge,
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              onNotifyTap: () => context.push('/me/messages'),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(communityTagsProvider);
                _invalidateVisiblePosts(keyword);
                ref.invalidate(unreadMessageCountProvider);
                await Future.wait([
                  ref.read(communityTagsProvider.future),
                  ref.read(unreadMessageCountProvider.future),
                  _readVisiblePosts(keyword),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: listPadding,
                children: [
                  _FeedScopeSwitcher(
                    selected: _scope,
                    onChanged: (scope) {
                      if (_scope == scope) {
                        return;
                      }
                      setState(() => _scope = scope);
                    },
                  ),
                  SizedBox(height: metrics.size(16)),
                  tags.when(
                    data: (items) => items.isEmpty
                        ? const SizedBox.shrink()
                        : _TopicFollowStrip(
                            tags: items,
                            onTap: _toggleFollowTag,
                          ),
                    error: (_, _) => const SizedBox.shrink(),
                    loading: () => const SizedBox(
                      height: 42,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: metrics.size(18)),
                  posts.when(
                    data: (page) => page.list.isEmpty
                        ? _CommunityEmptyState(query: _query, scope: _scope)
                        : Column(
                            children: [
                              for (final post in page.list)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: metrics.size(14),
                                  ),
                                  child: CommunityPostCard(
                                    post: post,
                                    onPostChanged: () =>
                                        _invalidateVisiblePosts(keyword),
                                  ),
                                ),
                            ],
                          ),
                    error: (error, _) => _StatusCard(
                      title: context.l10n.networkUnavailable,
                      message: error.toString(),
                      onRetry: () {
                        _invalidateVisiblePosts(keyword);
                      },
                    ),
                    loading: () => const _FeedLoading(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AsyncValue<CommunityPage<CommunityPost>> _watchPosts(String keyword) {
    if (_scope == _CommunityFeedScope.following) {
      return keyword.isEmpty
          ? ref.watch(communityFollowingPostsProvider)
          : ref.watch(communityFollowingPostsSearchProvider(keyword));
    }
    if (_scope == _CommunityFeedScope.topics) {
      return keyword.isEmpty
          ? ref.watch(communityFollowedTopicPostsProvider)
          : ref.watch(communityFollowedTopicPostsSearchProvider(keyword));
    }
    return keyword.isEmpty
        ? ref.watch(communityPostsProvider)
        : ref.watch(communityPostsSearchProvider(keyword));
  }

  Future<CommunityPage<CommunityPost>> _readVisiblePosts(String keyword) {
    if (_scope == _CommunityFeedScope.following) {
      return keyword.isEmpty
          ? ref.read(communityFollowingPostsProvider.future)
          : ref.read(communityFollowingPostsSearchProvider(keyword).future);
    }
    if (_scope == _CommunityFeedScope.topics) {
      return keyword.isEmpty
          ? ref.read(communityFollowedTopicPostsProvider.future)
          : ref.read(communityFollowedTopicPostsSearchProvider(keyword).future);
    }
    return keyword.isEmpty
        ? ref.read(communityPostsProvider.future)
        : ref.read(communityPostsSearchProvider(keyword).future);
  }

  void _invalidateVisiblePosts(String keyword) {
    if (_scope == _CommunityFeedScope.following) {
      ref.invalidate(communityFollowingPostsProvider);
      if (keyword.isNotEmpty) {
        ref.invalidate(communityFollowingPostsSearchProvider(keyword));
      }
      return;
    }
    if (_scope == _CommunityFeedScope.topics) {
      ref.invalidate(communityFollowedTopicPostsProvider);
      if (keyword.isNotEmpty) {
        ref.invalidate(communityFollowedTopicPostsSearchProvider(keyword));
      }
      return;
    }
    ref.invalidate(communityPostsProvider);
    if (keyword.isNotEmpty) {
      ref.invalidate(communityPostsSearchProvider(keyword));
    }
  }

  Future<void> _toggleFollowTag(CommunityTag tag) async {
    try {
      await ref.read(communityRepositoryProvider).toggleFollowTag(tag.id);
      ref.invalidate(communityTagsProvider);
      ref.invalidate(communityPostsProvider);
      ref.invalidate(communityFollowedTopicPostsProvider);
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        tag.isFollowed
            ? _t(context, '已取消关注标签', 'Tag unfollowed')
            : _t(context, '已关注标签', 'Tag followed'),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }
}

class CommunityPostCard extends ConsumerWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    this.showFollowButton = true,
    this.routeToDetail = true,
    this.onPostChanged,
  });

  final CommunityPost post;
  final bool showFollowButton;
  final bool routeToDetail;
  final VoidCallback? onPostChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _CommunityFeedPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final currentMemberId = int.tryParse(session?.memberId ?? '') ?? 0;
    final canFollow =
        showFollowButton &&
        !post.isAnonymous &&
        post.memberId > 0 &&
        post.memberId != currentMemberId;
    final openProfile = !post.isAnonymous && post.memberId > 0
        ? () => context.push('/community/profile/${post.memberId}')
        : null;

    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: routeToDetail
              ? () => context.push('/community/post/${post.id}')
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: openProfile,
                        child: _AuthorAvatar(
                          avatarUrl: apiClient.resolveUrl(post.authorAvatar),
                          isDoctor: post.isDoctorPost,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: openProfile,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.primaryText,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _authorSubtitle(context, post),
                              style: TextStyle(
                                color: palette.secondaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (canFollow)
                      _FollowButton(
                        followed: post.isFollowedAuthor,
                        mutualFollowed: post.isMutualFollowAuthor,
                        onTap: () => _toggleFollowAuthor(context, ref, post),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (post.images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PostImageGrid(
                      images: post.images
                          .map(apiClient.resolveUrl)
                          .where((url) => url.trim().isNotEmpty)
                          .toList(growable: false),
                    ),
                  ),
                if (post.hasTitle) ...[
                  Text(
                    post.title,
                    maxLines: routeToDetail ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 18,
                      height: 1.35,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  post.hasTitle ? post.body : post.content,
                  maxLines: routeToDetail ? 7 : 5,
                  overflow: routeToDetail ? TextOverflow.ellipsis : null,
                  style: TextStyle(
                    color: palette.bodyText,
                    fontSize: 15,
                    height: 1.7,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (post.linkUrl.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _LinkPreview(url: post.linkUrl),
                ],
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in post.tags.take(4))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: palette.softBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '# $tag',
                            style: TextStyle(
                              color: palette.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ActionChip(
                      icon: Icons.mode_comment_outlined,
                      text: '${post.commentCount}',
                      onTap: () => context.push('/community/post/${post.id}'),
                    ),
                    const SizedBox(width: 10),
                    _ActionChip(
                      icon: post.isLiked
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_off_alt_rounded,
                      text: '${post.likeCount}',
                      active: post.isLiked,
                      onTap: () => _toggleLike(context, ref, post.id),
                    ),
                    const SizedBox(width: 10),
                    _ActionChip(
                      icon: post.isCollected
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      text: '${post.collectCount}',
                      active: post.isCollected,
                      onTap: () => _toggleCollect(context, ref, post.id),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: _t(context, '举报帖子', 'Report post'),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _reportPost(context, ref, post.id),
                      icon: Icon(
                        Icons.flag_outlined,
                        size: 20,
                        color: palette.secondaryText,
                      ),
                    ),
                    Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: palette.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.viewCount}',
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(
    BuildContext context,
    WidgetRef ref,
    int postId,
  ) async {
    try {
      await ref.read(communityRepositoryProvider).togglePostLike(postId);
      ref.invalidate(communityPostsProvider);
      ref.invalidate(communityFollowingPostsProvider);
      ref.invalidate(communityFollowedTopicPostsProvider);
      ref.invalidate(communityPostProvider(postId));
      onPostChanged?.call();
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  Future<void> _toggleCollect(
    BuildContext context,
    WidgetRef ref,
    int postId,
  ) async {
    try {
      await ref.read(communityRepositoryProvider).togglePostCollect(postId);
      ref.invalidate(communityPostsProvider);
      ref.invalidate(communityFollowingPostsProvider);
      ref.invalidate(communityFollowedTopicPostsProvider);
      ref.invalidate(communityPostProvider(postId));
      onPostChanged?.call();
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  Future<void> _toggleFollowAuthor(
    BuildContext context,
    WidgetRef ref,
    CommunityPost post,
  ) async {
    try {
      final state = await ref
          .read(communityRepositoryProvider)
          .toggleFollowMember(post.memberId);
      ref.invalidate(communityPostsProvider);
      ref.invalidate(communityFollowingPostsProvider);
      ref.invalidate(communityFollowedTopicPostsProvider);
      ref.invalidate(communityPostProvider(post.id));
      onPostChanged?.call();
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(_followNoticeText(context, state));
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  Future<void> _reportPost(
    BuildContext context,
    WidgetRef ref,
    int postId,
  ) async {
    final draft = await showCommunityReportSheet(
      context,
      title: _t(context, '举报帖子', 'Report post'),
    );
    if (draft == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(communityRepositoryProvider)
          .reportTarget(
            targetType: 1,
            targetId: postId,
            reason: draft.reason,
            description: draft.description,
          );
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(_t(context, '举报已提交', 'Report submitted'));
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }
}

class _CommunityTopBar extends StatelessWidget {
  const _CommunityTopBar({
    required this.avatarUrl,
    required this.badge,
    required this.controller,
    required this.onChanged,
    required this.onNotifyTap,
  });

  final String avatarUrl;
  final String? badge;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onNotifyTap;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    final metrics = AppTabShellMetrics.of(context);
    return SizedBox(
      height: metrics.size(AppTabShellMetrics.headerBlockHeight),
      child: Row(
        children: [
          _AuthorAvatar(
            avatarUrl: avatarUrl,
            isDoctor: false,
            size: metrics.size(AppTabShellMetrics.headerAvatarSize),
          ),
          SizedBox(width: metrics.size(AppTabShellMetrics.headerSpacing)),
          Expanded(
            child: Container(
              height: metrics.size(50),
              decoration: BoxDecoration(
                color: palette.cardBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: palette.secondaryText,
                  ),
                  hintText: _t(context, '开始探索', 'Search support'),
                  hintStyle: TextStyle(color: palette.secondaryText),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: metrics.size(14),
                  ),
                ),
                style: TextStyle(color: palette.primaryText),
              ),
            ),
          ),
          SizedBox(width: metrics.size(12)),
          _CircleButton(
            icon: Icons.notifications_none_rounded,
            badge: badge,
            onTap: onNotifyTap,
          ),
        ],
      ),
    );
  }
}

class _FeedScopeSwitcher extends StatelessWidget {
  const _FeedScopeSwitcher({required this.selected, required this.onChanged});

  final _CommunityFeedScope selected;
  final ValueChanged<_CommunityFeedScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    final metrics = AppTabShellMetrics.of(context);

    return Container(
      height: metrics.size(48),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _FeedScopeSegment(
            scope: _CommunityFeedScope.public,
            selected: selected == _CommunityFeedScope.public,
            onTap: () => onChanged(_CommunityFeedScope.public),
          ),
          _FeedScopeSegment(
            scope: _CommunityFeedScope.following,
            selected: selected == _CommunityFeedScope.following,
            onTap: () => onChanged(_CommunityFeedScope.following),
          ),
          _FeedScopeSegment(
            scope: _CommunityFeedScope.topics,
            selected: selected == _CommunityFeedScope.topics,
            onTap: () => onChanged(_CommunityFeedScope.topics),
          ),
        ],
      ),
    );
  }
}

class _FeedScopeSegment extends StatelessWidget {
  const _FeedScopeSegment({
    required this.scope,
    required this.selected,
    required this.onTap,
  });

  final _CommunityFeedScope scope;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final activeBackground = isDark
        ? const Color(0xFFFFB4A8)
        : const Color(0xFFFF9585);
    final activeForeground = isDark ? const Color(0xFF3B2420) : Colors.white;

    return Expanded(
      child: Material(
        color: selected ? activeBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Center(
            child: Text(
              _scopeLabel(context, scope),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? activeForeground : palette.secondaryText,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _badgeText(int count) {
  if (count <= 0) {
    return null;
  }
  return count > 99 ? '99+' : '$count';
}

class CommunityReportDraft {
  const CommunityReportDraft({required this.reason, required this.description});

  final String reason;
  final String description;
}

Future<CommunityReportDraft?> showCommunityReportSheet(
  BuildContext context, {
  required String title,
}) async {
  final reasonController = TextEditingController();
  final descriptionController = TextEditingController();
  try {
    return await showDialog<CommunityReportDraft>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: reasonController,
                    autofocus: true,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: _t(sheetContext, '举报原因', 'Reason'),
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    minLines: 3,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: _t(
                        sheetContext,
                        '补充描述（可选）',
                        'Details (optional)',
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(_t(sheetContext, '取消', 'Cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      setState(() {
                        errorText = _t(
                          sheetContext,
                          '请填写举报原因',
                          'Please enter a reason',
                        );
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      CommunityReportDraft(
                        reason: reason,
                        description: descriptionController.text.trim(),
                      ),
                    );
                  },
                  child: Text(_t(sheetContext, '提交', 'Submit')),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    reasonController.dispose();
    descriptionController.dispose();
  }
}

class _TopicFollowStrip extends StatelessWidget {
  const _TopicFollowStrip({required this.tags, required this.onTap});

  final List<CommunityTag> tags;
  final ValueChanged<CommunityTag> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    final metrics = AppTabShellMetrics.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(context, '话题关注', 'Topics'),
          style: TextStyle(
            color: palette.primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: metrics.size(10)),
        SizedBox(
          height: metrics.size(42),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final tag = tags[index];
              return _TopicChip(tag: tag, onTap: () => onTap(tag));
            },
            separatorBuilder: (_, _) => SizedBox(width: metrics.size(8)),
            itemCount: tags.length,
          ),
        ),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.tag, required this.onTap});

  final CommunityTag tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    final active = tag.isFollowed;

    return Material(
      color: active ? palette.selectedChipBackground : palette.cardBackground,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            '# ${tag.name}',
            style: TextStyle(
              color: active ? palette.selectedChipText : palette.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({
    required this.avatarUrl,
    required this.isDoctor,
    this.size = 54,
  });

  final String avatarUrl;
  final bool isDoctor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatar = avatarUrl.trim().isNotEmpty
        ? ClipOval(
            child: CachedRemoteImage(
              avatarUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(context),
            ),
          )
        : _fallback(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(width: size, height: size, child: avatar),
        if (isDoctor)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF5A81DA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.avatarBackground,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_rounded, color: Color(0xFFFF9585)),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.followed,
    required this.mutualFollowed,
    required this.onTap,
  });

  final bool followed;
  final bool mutualFollowed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: followed
            ? palette.selectedChipBackground
            : const Color(0xFFF49A86),
        foregroundColor: followed ? const Color(0xFFF49A86) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: Text(
        _followButtonLabel(
          context,
          isFollowed: followed,
          isMutualFollow: mutualFollowed,
        ),
      ),
    );
  }
}

class _PostImageGrid extends StatelessWidget {
  const _PostImageGrid({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final count = images.length.clamp(0, 4);
    if (count == 0) {
      return const SizedBox.shrink();
    }
    if (count == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 1.45,
          child: CachedRemoteImage(images.first, fit: BoxFit.cover),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.88,
        ),
        itemBuilder: (context, index) {
          return CachedRemoteImage(images[index], fit: BoxFit.cover);
        },
      ),
    );
  }
}

class _LinkPreview extends StatelessWidget {
  const _LinkPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Color(0xFF5A81DA)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.linkText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.text,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? palette.selectedChipBackground
              : palette.softBackground,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? palette.selectedChipText : palette.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: active
                    ? palette.selectedChipText
                    : palette.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityEmptyState extends StatelessWidget {
  const _CommunityEmptyState({required this.query, required this.scope});

  final String query;
  final _CommunityFeedScope scope;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    final hasQuery = query.trim().isNotEmpty;
    final isFollowing = scope == _CommunityFeedScope.following;
    final isTopics = scope == _CommunityFeedScope.topics;
    final message = hasQuery
        ? _t(context, '没有找到相关动态', 'No matching posts')
        : isFollowing
        ? _t(context, '关注的人还没有发帖', 'No posts from people you follow')
        : isTopics
        ? _t(context, '关注的话题还没有动态', 'No posts in followed topics')
        : context.l10n.communityFeedEmpty;
    final helper = hasQuery
        ? _t(
            context,
            '你可以换个关键词，或者直接发布你的第一条支持内容。',
            'Try another keyword or publish your first support post.',
          )
        : isFollowing
        ? _t(
            context,
            '去广场发现更多作者，关注后这里会出现他们的动态。',
            'Find more authors in the public feed. Their posts will appear here after you follow them.',
          )
        : isTopics
        ? _t(
            context,
            '先在话题栏关注标签，相关帖子会集中出现在这里。',
            'Follow tags in the topic bar. Matching posts will appear here.',
          )
        : _t(context, '你可以发布第一条支持内容。', 'Publish your first support post.');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(Icons.forum_outlined, size: 52, color: Color(0xFFFF9585)),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helper,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.message, this.onRetry});

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.mutedText, height: 1.5),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [_LoadingCard(), SizedBox(height: 14), _LoadingCard()],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap, this.badge});

  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    final metrics = AppTabShellMetrics.of(context);
    final buttonSize = metrics.size(AppTabShellMetrics.actionButtonSize);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: palette.cardBackground,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: Icon(
                icon,
                size: metrics.size(AppTabShellMetrics.actionIconSize),
                color: palette.primaryText,
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: metrics.size(18),
              height: metrics.size(18),
              decoration: const BoxDecoration(
                color: Color(0xFFFF5B77),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _authorSubtitle(BuildContext context, CommunityPost post) {
  final role = post.isDoctorPost
      ? _t(context, '医生作者', 'Doctor author')
      : _t(context, '坚持治疗', 'Recovery journal');
  if (post.createTime.trim().isEmpty) {
    return role;
  }
  return '$role  ${post.createTime}';
}

String _scopeLabel(BuildContext context, _CommunityFeedScope scope) {
  return switch (scope) {
    _CommunityFeedScope.public => _t(context, '广场', 'Public'),
    _CommunityFeedScope.following => _t(context, '关注', 'Following'),
    _CommunityFeedScope.topics => _t(context, '话题', 'Topics'),
  };
}

String _followButtonLabel(
  BuildContext context, {
  required bool isFollowed,
  required bool isMutualFollow,
}) {
  if (isMutualFollow) {
    return _t(context, '已互关', 'Mutual');
  }
  if (isFollowed) {
    return _t(context, '已关注', 'Following');
  }
  return _t(context, '关注', 'Follow');
}

String _followNoticeText(BuildContext context, CommunityFollowState state) {
  if (!state.isFollowed) {
    return _t(context, '已取消关注', 'Unfollowed');
  }
  if (state.isMutualFollow) {
    return _t(context, '已互关', 'Mutual');
  }
  return _t(context, '已关注', 'Followed');
}

String _firstText(List<Object?> values, {String fallback = ''}) {
  for (final value in values) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty && text != 'null') {
      return text;
    }
  }
  return fallback;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _CommunityFeedPalette {
  const _CommunityFeedPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.bodyText,
    required this.selectedChipBackground,
    required this.selectedChipText,
    required this.avatarBackground,
    required this.linkText,
  });

  factory _CommunityFeedPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _CommunityFeedPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      softBackground: scheme.surfaceContainerLow,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
          : const Color(0xFF7D828A),
      bodyText: isDark
          ? scheme.onSurface.withValues(alpha: 0.84)
          : const Color(0xFF3D414A),
      selectedChipBackground: isDark
          ? scheme.primaryContainer.withValues(alpha: 0.5)
          : const Color(0xFFFFEEE9),
      selectedChipText: isDark
          ? scheme.onPrimaryContainer
          : const Color(0xFFF49A86),
      avatarBackground: isDark
          ? scheme.primaryContainer.withValues(alpha: 0.28)
          : const Color(0xFFF8E3DB),
      linkText: isDark ? scheme.primary : const Color(0xFF5A81DA),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color bodyText;
  final Color selectedChipBackground;
  final Color selectedChipText;
  final Color avatarBackground;
  final Color linkText;
}
