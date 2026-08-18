import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cache/cached_remote_image.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/community_controller.dart';
import '../data/community_models.dart';

enum CommunityRelationType { following, followers }

class CommunityMemberRelationsScreen extends ConsumerStatefulWidget {
  const CommunityMemberRelationsScreen({
    super.key,
    required this.memberId,
    required this.type,
  });

  final int memberId;
  final CommunityRelationType type;

  @override
  ConsumerState<CommunityMemberRelationsScreen> createState() =>
      _CommunityMemberRelationsScreenState();
}

class _CommunityMemberRelationsScreenState
    extends ConsumerState<CommunityMemberRelationsScreen> {
  final Set<int> _submittingMemberIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final palette = _RelationPalette.of(context);
    final profile = ref.watch(communityMemberProfileProvider(widget.memberId));
    final members = widget.type == CommunityRelationType.following
        ? ref.watch(communityFollowingProvider(widget.memberId))
        : ref.watch(communityFollowersProvider(widget.memberId));
    final apiClient = ref.watch(apiClientProvider);

    final defaultTitle = widget.type == CommunityRelationType.following
        ? _t(context, '我的关注', 'Following')
        : _t(context, '我的粉丝', 'Followers');

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: profile.when(
          data: (value) => Text(_title(context, value)),
          error: (_, _) => Text(defaultTitle),
          loading: () => Text(defaultTitle),
        ),
        centerTitle: true,
        backgroundColor: palette.appBarBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(communityMemberProfileProvider(widget.memberId));
            ref.invalidate(communityFollowingProvider(widget.memberId));
            ref.invalidate(communityFollowersProvider(widget.memberId));
            await Future.wait([
              ref.read(communityMemberProfileProvider(widget.memberId).future),
              ref.read(
                (widget.type == CommunityRelationType.following
                        ? communityFollowingProvider(widget.memberId)
                        : communityFollowersProvider(widget.memberId))
                    .future,
              ),
            ]);
          },
          child: members.when(
            data: (page) => page.list.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      _RelationStatusCard(
                        title: widget.type == CommunityRelationType.following
                            ? _t(context, '还没有关注任何人', 'No following yet')
                            : _t(context, '还没有新的粉丝', 'No followers yet'),
                        subtitle: widget.type == CommunityRelationType.following
                            ? _t(
                                context,
                                '去社区发现值得长期关注的同路人。',
                                'Explore the community and follow people worth keeping up with.',
                              )
                            : _t(
                                context,
                                '当别人关注你时，会出现在这里。',
                                'People who follow you will appear here.',
                              ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    itemCount: page.list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = page.list[index];
                      return _RelationMemberCard(
                        member: item,
                        avatarUrl: apiClient.resolveUrl(item.avatar),
                        submitting: _submittingMemberIds.contains(
                          item.memberId,
                        ),
                        onTap: item.isSelf
                            ? null
                            : () => context.push(
                                '/community/profile/${item.memberId}',
                              ),
                        onFollow: item.isSelf
                            ? null
                            : () => _toggleFollow(context, item),
                      );
                    },
                  ),
            error: (error, _) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _RelationStatusCard(
                  title: _t(context, '列表加载失败', 'Load failed'),
                  subtitle: error.toString(),
                ),
              ],
            ),
            loading: () => ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: List.generate(
                6,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    height: 118,
                    decoration: BoxDecoration(
                      color: palette.cardBackground,
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _title(BuildContext context, CommunityMemberProfile profile) {
    final isFollowing = widget.type == CommunityRelationType.following;
    if (profile.isSelf) {
      return isFollowing
          ? _t(context, '我的关注', 'Following')
          : _t(context, '我的粉丝', 'Followers');
    }
    return isFollowing
        ? _t(
            context,
            '${profile.displayName}的关注',
            '${profile.displayName} following',
          )
        : _t(
            context,
            '${profile.displayName}的粉丝',
            '${profile.displayName} followers',
          );
  }

  Future<void> _toggleFollow(
    BuildContext context,
    CommunityMember member,
  ) async {
    if (_submittingMemberIds.contains(member.memberId)) {
      return;
    }

    setState(() => _submittingMemberIds.add(member.memberId));
    try {
      final state = await ref
          .read(communityRepositoryProvider)
          .toggleFollowMember(member.memberId);
      ref.invalidate(communityFollowingProvider(widget.memberId));
      ref.invalidate(communityFollowersProvider(widget.memberId));
      ref.invalidate(communityMemberProfileProvider(widget.memberId));
      ref.invalidate(communityMemberProfileProvider(member.memberId));
      ref.invalidate(communityPostsProvider);
      ref.invalidate(communityFollowingPostsProvider);
      ref.invalidate(communityFollowedTopicPostsProvider);
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(_followNoticeText(context, state));
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    } finally {
      if (mounted) {
        setState(() => _submittingMemberIds.remove(member.memberId));
      }
    }
  }
}

class _RelationMemberCard extends StatelessWidget {
  const _RelationMemberCard({
    required this.member,
    required this.avatarUrl,
    required this.submitting,
    this.onTap,
    this.onFollow,
  });

  final CommunityMember member;
  final String avatarUrl;
  final bool submitting;
  final VoidCallback? onTap;
  final VoidCallback? onFollow;

  @override
  Widget build(BuildContext context) {
    final palette = _RelationPalette.of(context);
    final card = Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 72,
              height: 72,
              child: avatarUrl.isEmpty
                  ? ColoredBox(
                      color: palette.avatarBackground,
                      child: Icon(
                        Icons.person_rounded,
                        color: palette.avatarIcon,
                        size: 30,
                      ),
                    )
                  : CachedRemoteImage(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.person_rounded,
                        color: palette.avatarIcon,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (member.isDoctor) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF5A81DA),
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  member.bio.trim().isEmpty
                      ? _t(
                          context,
                          '努力治愈好每一个病人',
                          'Keep helping one person at a time.',
                        )
                      : member.bio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (onFollow != null) ...[
            const SizedBox(width: 14),
            FilledButton(
              onPressed: submitting ? null : onFollow,
              style: FilledButton.styleFrom(
                backgroundColor: member.isFollowed
                    ? palette.followedButtonBackground
                    : palette.followButtonBackground,
                foregroundColor: Colors.white,
                minimumSize: const Size(112, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _followButtonLabel(
                        context,
                        isFollowed: member.isFollowed,
                        isMutualFollow: member.isMutualFollow,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _RelationStatusCard extends StatelessWidget {
  const _RelationStatusCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = _RelationPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
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

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _RelationPalette {
  const _RelationPalette({
    required this.pageBackground,
    required this.appBarBackground,
    required this.cardBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.avatarBackground,
    required this.avatarIcon,
    required this.followButtonBackground,
    required this.followedButtonBackground,
  });

  static _RelationPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _RelationPalette(
      pageBackground: scheme.surface,
      appBarBackground: isDark ? scheme.surface : scheme.surfaceContainerLowest,
      cardBackground: scheme.surfaceContainerLowest,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      avatarBackground: isDark
          ? scheme.surfaceContainerHighest
          : const Color(0xFFEAF0FF),
      avatarIcon: isDark ? scheme.tertiary : const Color(0xFF8EA8F8),
      followButtonBackground: const Color(0xFFF49C8C),
      followedButtonBackground: isDark
          ? const Color(0xFF6B4A47)
          : const Color(0xFFF7D7D1),
    );
  }

  final Color pageBackground;
  final Color appBarBackground;
  final Color cardBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color avatarBackground;
  final Color avatarIcon;
  final Color followButtonBackground;
  final Color followedButtonBackground;
}
