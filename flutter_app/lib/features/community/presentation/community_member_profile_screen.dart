import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/community_controller.dart';
import '../data/community_models.dart';
import 'community_feed_screen.dart';

class CommunityMemberProfileScreen extends ConsumerStatefulWidget {
  const CommunityMemberProfileScreen({super.key, required this.memberId});

  final int memberId;

  @override
  ConsumerState<CommunityMemberProfileScreen> createState() =>
      _CommunityMemberProfileScreenState();
}

class _CommunityMemberProfileScreenState
    extends ConsumerState<CommunityMemberProfileScreen> {
  bool _followingSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(communityMemberProfileProvider(widget.memberId));
    final posts = ref.watch(communityMemberPostsProvider(widget.memberId));
    final apiClient = ref.watch(apiClientProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: SafeArea(
        child: profile.when(
          data: (member) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(communityMemberProfileProvider(widget.memberId));
              ref.invalidate(communityMemberPostsProvider(widget.memberId));
              await Future.wait([
                ref.read(
                  communityMemberProfileProvider(widget.memberId).future,
                ),
                ref.read(communityMemberPostsProvider(widget.memberId).future),
              ]);
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ProfileHero(
                  profile: member,
                  avatarUrl: apiClient.resolveUrl(member.avatar),
                  followBusy: _followingSubmitting,
                  onBack: () => Navigator.of(context).maybePop(),
                  onFollow: member.isSelf
                      ? null
                      : () => _toggleFollow(context, member),
                ),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _StatPanel(
                      profile: member,
                      onFollowingTap: () => context.push(
                        '/community/relations/following/${member.memberId}',
                      ),
                      onFollowersTap: () => context.push(
                        '/community/relations/followers/${member.memberId}',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    member.isSelf
                        ? _t(context, '我的发布', 'My posts')
                        : _t(context, '他的发布', 'Posts'),
                    style: const TextStyle(
                      color: Color(0xFF303236),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: posts.when(
                    data: (page) => page.list.isEmpty
                        ? const _ProfileEmptyState()
                        : Column(
                            children: [
                              for (final post in page.list) ...[
                                CommunityPostCard(
                                  post: post,
                                  showFollowButton: false,
                                ),
                                const SizedBox(height: 14),
                              ],
                            ],
                          ),
                    error: (error, _) => _ProfileStatusCard(
                      title: _t(context, '加载失败', 'Load failed'),
                      subtitle: error.toString(),
                    ),
                    loading: () => const _ProfileLoadingList(),
                  ),
                ),
              ],
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _ProfileStatusCard(
                title: _t(context, '主页加载失败', 'Profile unavailable'),
                subtitle: error.toString(),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _toggleFollow(
    BuildContext context,
    CommunityMemberProfile profile,
  ) async {
    if (_followingSubmitting) {
      return;
    }

    setState(() => _followingSubmitting = true);
    try {
      await ref
          .read(communityRepositoryProvider)
          .toggleFollowMember(profile.memberId);
      ref.invalidate(communityMemberProfileProvider(widget.memberId));
      ref.invalidate(communityFollowingProvider(widget.memberId));
      ref.invalidate(communityFollowersProvider(widget.memberId));
      ref.invalidate(communityPostsProvider);
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(
        profile.isFollowed
            ? _t(context, '已取消关注', 'Unfollowed')
            : _t(context, '已关注', 'Followed'),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    } finally {
      if (mounted) {
        setState(() => _followingSubmitting = false);
      }
    }
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.avatarUrl,
    required this.followBusy,
    required this.onBack,
    this.onFollow,
  });

  final CommunityMemberProfile profile;
  final String avatarUrl;
  final bool followBusy;
  final VoidCallback onBack;
  final VoidCallback? onFollow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF113754),
                    Color(0xFF375E7A),
                    Color(0xFF8B7A69),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: CustomPaint(painter: _ProfileBackdropPainter()),
            ),
          ),
          Positioned(
            top: 10,
            left: 14,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 26,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withValues(alpha: 0.96),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFFEAF0FF),
                    backgroundImage: avatarUrl.isEmpty
                        ? null
                        : NetworkImage(avatarUrl),
                    child: avatarUrl.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            color: Color(0xFF8EA8F8),
                            size: 46,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (profile.isDoctor) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFFBFD4FF),
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          profile.bio.trim().isEmpty
                              ? _t(
                                  context,
                                  '希望大家一起努力，活得精彩！',
                                  'Let us keep moving forward together.',
                                )
                              : profile.bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (onFollow != null) ...[
                  const SizedBox(width: 12),
                  _FollowActionButton(
                    followed: profile.isFollowed,
                    busy: followBusy,
                    onTap: onFollow!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPanel extends StatelessWidget {
  const _StatPanel({
    required this.profile,
    required this.onFollowingTap,
    required this.onFollowersTap,
  });

  final CommunityMemberProfile profile;
  final VoidCallback onFollowingTap;
  final VoidCallback onFollowersTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              value: _countText(profile.followCount),
              label: _t(context, '关注', 'Following'),
              onTap: onFollowingTap,
            ),
          ),
          Expanded(
            child: _StatItem(
              value: _countText(profile.followerCount),
              label: _t(context, '粉丝', 'Followers'),
              onTap: onFollowersTap,
            ),
          ),
          Expanded(
            child: _StatItem(
              value: _countText(profile.likeCount),
              label: _t(context, '获赞', 'Likes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF303236),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF96999F),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: child,
      ),
    );
  }
}

class _FollowActionButton extends StatelessWidget {
  const _FollowActionButton({
    required this.followed,
    required this.busy,
    required this.onTap,
  });

  final bool followed;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: followed
            ? const Color(0xFFF8D6CF)
            : const Color(0xFFF49C8C),
        foregroundColor: Colors.white,
        minimumSize: const Size(112, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              followed
                  ? _t(context, '已关注', 'Following')
                  : _t(context, '关注', 'Follow'),
            ),
    );
  }
}

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState();

  @override
  Widget build(BuildContext context) {
    return _ProfileStatusCard(
      title: _t(context, '暂无社区发布', 'No community posts yet'),
      subtitle: _t(
        context,
        '这里还没有公开展示的帖子内容。',
        'There are no public posts here yet.',
      ),
    );
  }
}

class _ProfileStatusCard extends StatelessWidget {
  const _ProfileStatusCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7D828A),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLoadingList extends StatelessWidget {
  const _ProfileLoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 224,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    paint.shader = const LinearGradient(
      colors: [Color(0xFFA46C1B), Color(0xFFF0C57F)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path()
      ..moveTo(-20, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.36,
        size.width * 0.42,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.18,
        size.width * 0.78,
        size.height * 0.4,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.5,
        size.width + 24,
        size.height * 0.28,
      )
      ..lineTo(size.width + 24, size.height)
      ..lineTo(-20, size.height)
      ..close();
    canvas.drawPath(path, paint);

    paint.shader = const LinearGradient(
      colors: [Color(0xFFE9EEF5), Color(0xFFBFD0DB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final snowyPath = Path()
      ..moveTo(-20, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.52,
        size.width * 0.44,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.42,
        size.width * 0.82,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.66,
        size.width + 24,
        size.height * 0.54,
      )
      ..lineTo(size.width + 24, size.height)
      ..lineTo(-20, size.height)
      ..close();
    canvas.drawPath(snowyPath, paint);

    paint
      ..shader = null
      ..color = Colors.white.withValues(alpha: 0.08);
    for (var i = 0; i < 5; i += 1) {
      canvas.drawCircle(
        Offset(size.width * (0.12 + i * 0.18), size.height * (0.18 + i * 0.03)),
        22 + i * 3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _countText(int value) {
  if (value >= 10000) {
    return '${(value / 10000).round()}W';
  }
  return '$value';
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
