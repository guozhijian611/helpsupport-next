import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
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

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    final posts = _query.trim().isEmpty
        ? ref.watch(communityPostsProvider)
        : ref.watch(communityPostsSearchProvider(_query.trim()));
    final tags = ref.watch(communityTagsProvider);
    final unreadCount = ref.watch(unreadMessageCountProvider);
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final avatarUrl = _firstText([session?.member['avatar']]);
    final badge = _badgeText(unreadCount.asData?.value ?? 0);

    return ColoredBox(
      color: palette.pageBackground,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(communityTagsProvider);
          ref.invalidate(communityPostsProvider);
          ref.invalidate(unreadMessageCountProvider);
          if (_query.trim().isNotEmpty) {
            ref.invalidate(communityPostsSearchProvider(_query.trim()));
          }
          await Future.wait([
            ref.read(communityTagsProvider.future),
            ref.read(unreadMessageCountProvider.future),
            _query.trim().isEmpty
                ? ref.read(communityPostsProvider.future)
                : ref.read(communityPostsSearchProvider(_query.trim()).future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 94),
          children: [
            _CommunityTopBar(
              avatarUrl: avatarUrl,
              badge: badge,
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              onNotifyTap: () => context.push('/me/messages'),
            ),
            const SizedBox(height: 16),
            tags.when(
              data: (items) => items.isEmpty
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final tag = items[index];
                          return _TopicChip(
                            tag: tag,
                            onTap: () => _toggleFollowTag(tag),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemCount: items.length,
                      ),
                    ),
              error: (_, _) => const SizedBox.shrink(),
              loading: () => const SizedBox(
                height: 42,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
            const SizedBox(height: 18),
            posts.when(
              data: (page) => page.list.isEmpty
                  ? _CommunityEmptyState(query: _query)
                  : Column(
                      children: [
                        for (final post in page.list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: CommunityPostCard(post: post),
                          ),
                      ],
                    ),
              error: (error, _) => _StatusCard(
                title: context.l10n.networkUnavailable,
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(communityPostsProvider);
                  if (_query.trim().isNotEmpty) {
                    ref.invalidate(communityPostsSearchProvider(_query.trim()));
                  }
                },
              ),
              loading: () => const _FeedLoading(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFollowTag(CommunityTag tag) async {
    try {
      await ref.read(communityRepositoryProvider).toggleFollowTag(tag.id);
      ref.invalidate(communityTagsProvider);
      ref.invalidate(communityPostsProvider);
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
  });

  final CommunityPost post;
  final bool showFollowButton;
  final bool routeToDetail;

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
      ref.invalidate(communityPostProvider(postId));
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
      ref.invalidate(communityPostProvider(postId));
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
      await ref
          .read(communityRepositoryProvider)
          .toggleFollowMember(post.memberId);
      ref.invalidate(communityPostsProvider);
      ref.invalidate(communityPostProvider(post.id));
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(
        post.isFollowedAuthor
            ? _t(context, '已取消关注', 'Unfollowed')
            : _t(context, '已关注', 'Followed'),
      );
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
    return Row(
      children: [
        _AuthorAvatar(avatarUrl: avatarUrl, isDoctor: false, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 50,
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
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: TextStyle(color: palette.primaryText),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _CircleButton(
          icon: Icons.notifications_none_rounded,
          badge: badge,
          onTap: onNotifyTap,
        ),
      ],
    );
  }
}

String? _badgeText(int count) {
  if (count <= 0) {
    return null;
  }
  return count > 99 ? '99+' : '$count';
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
    final palette = _CommunityFeedPalette.of(context);
    final avatar = avatarUrl.trim().isNotEmpty
        ? ClipOval(
            child: Image.network(
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
  const _FollowButton({required this.followed, required this.onTap});

  final bool followed;
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
        followed
            ? _t(context, '已关注', 'Following')
            : _t(context, '关注', 'Follow'),
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
          child: Image.network(images.first, fit: BoxFit.cover),
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
          return Image.network(images[index], fit: BoxFit.cover);
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
  const _CommunityEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityFeedPalette.of(context);
    final message = query.trim().isEmpty
        ? context.l10n.communityFeedEmpty
        : _t(context, '没有找到相关动态', 'No matching posts');

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
            _t(
              context,
              '你可以换个关键词，或者直接发布你的第一条支持内容。',
              'Try another keyword or publish your first support post.',
            ),
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
              width: 48,
              height: 48,
              child: Icon(icon, color: palette.primaryText),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 18,
              height: 18,
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
