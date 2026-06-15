import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../auth/application/auth_controller.dart';
import '../../chat/application/chat_controller.dart';
import '../../chat/data/chat_models.dart';
import '../../chat/presentation/chat_launch_sheet.dart';
import '../../community/application/community_controller.dart';
import '../../plan/application/plan_controller.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  static const _pageBackground = Color(0xFFF4F5F9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final overview = ref.watch(chatOverviewProvider);
    final plans = ref.watch(currentPlansProvider);
    final community = ref.watch(communityPostsProvider);
    final plansData = switch (plans) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final communityData = switch (community) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final nickname = _firstText([
      session?.profile['nickname'],
      session?.member['nickname'],
      session?.member['username'],
      session?.member['mobile'],
    ], fallback: 'Alexandrina');
    final avatarUrl = _firstText([session?.member['avatar']]);

    return ColoredBox(
      color: _pageBackground,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(chatOverviewProvider);
          ref.invalidate(currentPlansProvider);
          ref.invalidate(communityPostsProvider);
          await Future.wait([
            ref.read(chatOverviewProvider.future),
            ref.read(currentPlansProvider.future),
            ref.read(communityPostsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          children: [
            _HomeHeader(
              name: nickname,
              avatarUrl: avatarUrl,
              onNotificationTap: () =>
                  context.showCenteredNotice(context.l10n.featureComingSoon),
            ),
            const SizedBox(height: 22),
            _HeroPanel(
              title: _t(context, '为康复做出关键决策', 'Make decisive recovery choices'),
              subtitle: _t(
                context,
                '最好的治疗方案，源于更深的病情沟通。',
                'Better treatment plans begin with deeper clinical dialogue.',
              ),
              buttonLabel: _t(context, '立即预约', 'Book now'),
              onTap: () => context.push('/appointments/doctors'),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SupportEntryCard(
                    title: _t(context, '教育素材', 'Learning'),
                    subtitle: _t(
                      context,
                      '知识塑造未来，学习改变人生',
                      'Insight builds the future. Learning changes recovery.',
                    ),
                    colors: const [Color(0xFF8EA8F8), Color(0xFF7F9DF0)],
                    icon: Icons.auto_stories_rounded,
                    onTap: () => context.push('/materials?type=education'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SupportEntryCard(
                    title: _t(context, '娱乐', 'Restore'),
                    subtitle: _t(
                      context,
                      '让大脑从高压里喘口气',
                      'Give your mind a softer place to land.',
                    ),
                    colors: const [Color(0xFFB695F6), Color(0xFFA280EC)],
                    icon: Icons.sports_esports_rounded,
                    onTap: () => context.push('/materials?type=entertainment'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionTitle(
              title: _t(context, '互动聊天', 'Interactive care'),
              trailing: TextButton(
                onPressed: () => context.push('/chat'),
                child: Text(_t(context, '查看全部', 'View all')),
              ),
            ),
            overview.when(
              data: (data) => Column(
                children: [
                  for (final mode in data.modes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ChatModeHeroCard(
                        mode: mode,
                        onPrimaryTap: () =>
                            _startSession(context, ref, mode.chatMode),
                      ),
                    ),
                  const SizedBox(height: 10),
                  _SectionTitle(
                    title: context.l10n.recentConversations,
                    trailing: Text(
                      _planSummaryText(context, plansData),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF96999F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (data.recentSessions.isEmpty)
                    _EmptyConversationCard(
                      text: _t(
                        context,
                        '还没有会话，先从一个 AI 支持模式开始。',
                        'No sessions yet. Start with an AI support mode first.',
                      ),
                    )
                  else
                    ...data.recentSessions
                        .take(4)
                        .map(
                          (session) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ConversationCard(
                              session: session,
                              onTap: () => _openSession(context, session),
                              onDelete: () =>
                                  _deleteSession(context, ref, session),
                            ),
                          ),
                        ),
                ],
              ),
              error: (error, _) => _InfoPanel(
                title: context.l10n.networkUnavailable,
                subtitle: error.toString(),
                actionLabel: context.l10n.retry,
                onPressed: () => ref.invalidate(chatOverviewProvider),
              ),
              loading: () => const _DashboardLoading(),
            ),
            const SizedBox(height: 10),
            _SectionTitle(
              title: _t(context, '最近社区动态', 'Recent community activity'),
              trailing: TextButton(
                onPressed: () => context.showCenteredNotice(
                  _communityTeaser(context, communityData),
                ),
                child: Text(_t(context, '摘要', 'Summary')),
              ),
            ),
            community.when(
              data: (page) => page.list.isEmpty
                  ? _InfoPanel(
                      title: context.l10n.communityFeedEmpty,
                      subtitle: _t(
                        context,
                        '当你准备好分享或阅读支持内容时，这里会出现真实动态。',
                        'Real support posts will appear here when the community is active.',
                      ),
                    )
                  : _CommunityTeaser(post: page.list.first),
              error: (error, _) => _InfoPanel(
                title: context.l10n.networkUnavailable,
                subtitle: error.toString(),
                actionLabel: context.l10n.retry,
                onPressed: () => ref.invalidate(communityPostsProvider),
              ),
              loading: () => const _InfoPanelSkeleton(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startSession(
    BuildContext context,
    WidgetRef ref,
    String chatMode,
  ) async {
    final option = await showChatLaunchSheet(
      context,
      title: _modeTitle(context, chatMode),
    );
    if (option == null || !context.mounted) {
      return;
    }
    if (option == ChatLaunchOption.local) {
      context.push(
        Uri(
          path: '/local-model',
          queryParameters: {
            'mode': chatMode,
            'title': _modeTitle(context, chatMode),
          },
        ).toString(),
      );
      return;
    }
    try {
      final session = await ref
          .read(chatRepositoryProvider)
          .createSession(chatMode);
      ref.invalidate(chatOverviewProvider);
      if (!context.mounted) {
        return;
      }
      _openSession(context, session);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    ChatSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t(context, '删除会话', 'Delete conversation')),
        content: Text(
          _t(
            context,
            '会话删除后将无法恢复，确认移除「${session.sessionName}」吗？',
            'This cannot be undone. Remove "${session.sessionName}"?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.backAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_t(context, '删除', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(chatRepositoryProvider).deleteSession(session.id);
      ref.invalidate(chatOverviewProvider);
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(_t(context, '会话已删除', 'Conversation deleted'));
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.avatarUrl,
    required this.onNotificationTap,
  });

  final String name;
  final String avatarUrl;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProfileAvatar(avatarUrl: avatarUrl, size: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(context, 'Good morning!', 'Good morning!'),
                style: const TextStyle(
                  color: Color(0xFFB0B3BA),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF303236),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _CircularActionButton(
          icon: Icons.notifications_none_rounded,
          badge: '5',
          onTap: onNotificationTap,
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF6FAEA6), Color(0xFF5B9F97)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFE5F7F3),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5B9F97),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                  ),
                  onPressed: onTap,
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          const SizedBox(width: 132, height: 156, child: _DoctorIllustration()),
        ],
      ),
    );
  }
}

class _SupportEntryCard extends StatelessWidget {
  const _SupportEntryCard({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: colors),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF6F4FF),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: Colors.white, size: 42),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ChatModeHeroCard extends StatelessWidget {
  const _ChatModeHeroCard({required this.mode, required this.onPrimaryTap});

  final ChatModeInfo mode;
  final VoidCallback onPrimaryTap;

  @override
  Widget build(BuildContext context) {
    final visual = _ModeVisualData.fromMode(context, mode.chatMode);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(colors: visual.colors),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _modeTitle(context, mode.chatMode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  mode.promptText.trim().isNotEmpty
                      ? mode.promptText
                      : _modeDescription(context, mode.chatMode),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF8F5FF),
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final label in visual.tags)
                      _ModeTag(label: label, backgroundColor: visual.tagColor),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: visual.buttonColor,
                    minimumSize: const Size(176, 48),
                  ),
                  onPressed: onPrimaryTap,
                  child: Text(_t(context, '开始体验', 'Start')),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          _ModeIllustration(visual: visual),
        ],
      ),
    );
  }
}

class _ModeTag extends StatelessWidget {
  const _ModeTag({required this.label, required this.backgroundColor});

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  final ChatSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Text(
                '#${session.id}',
                style: const TextStyle(
                  color: Color(0xFF303236),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.sessionName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _modeAccent(session.chatMode),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _conversationSubtitle(context, session),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF96999F),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFF19484),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF96999F)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyConversationCard extends StatelessWidget {
  const _EmptyConversationCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEEE9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFF9585),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF7D828A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTeaser extends StatelessWidget {
  const _CommunityTeaser({required this.post});

  final dynamic post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.authorName as String,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            post.content as String,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4A4D55),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetaChip(
                icon: Icons.forum_outlined,
                text: '${post.commentCount}',
              ),
              const SizedBox(width: 10),
              _MetaChip(
                icon: Icons.favorite_border_rounded,
                text: '${post.likeCount}',
              ),
              const SizedBox(width: 10),
              _MetaChip(
                icon: Icons.bookmark_border_rounded,
                text: '${post.collectCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7D828A)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF7D828A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7D828A),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: onPressed, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _InfoPanelSkeleton(height: 200),
        SizedBox(height: 14),
        _InfoPanelSkeleton(height: 200),
        SizedBox(height: 14),
        _InfoPanelSkeleton(height: 112),
      ],
    );
  }
}

class _InfoPanelSkeleton extends StatelessWidget {
  const _InfoPanelSkeleton({this.height = 140});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _CircularActionButton extends StatelessWidget {
  const _CircularActionButton({
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 50,
              height: 50,
              child: Icon(icon, color: const Color(0xFF303236)),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -3,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: const BoxDecoration(
                color: Color(0xFFFF5B77),
                shape: BoxShape.circle,
              ),
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.avatarUrl, this.size = 56});

  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final child = avatarUrl.isNotEmpty
        ? ClipOval(
            child: Image.network(
              avatarUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _avatarFallback(size),
            ),
          )
        : _avatarFallback(size);

    return SizedBox(width: size, height: size, child: child);
  }

  Widget _avatarFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFF8E3DB),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_rounded, color: Color(0xFFFF9585)),
    );
  }
}

class _ModeIllustration extends StatelessWidget {
  const _ModeIllustration({required this.visual});

  final _ModeVisualData visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: visual.circleColor,
      ),
      child: Icon(visual.icon, size: 54, color: Colors.white),
    );
  }
}

class _DoctorIllustration extends StatelessWidget {
  const _DoctorIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x55C6E6DF),
          ),
        ),
        const Icon(
          Icons.medical_services_rounded,
          color: Colors.white,
          size: 72,
        ),
      ],
    );
  }
}

class _ModeVisualData {
  const _ModeVisualData({
    required this.colors,
    required this.icon,
    required this.circleColor,
    required this.buttonColor,
    required this.tagColor,
    required this.tags,
  });

  final List<Color> colors;
  final IconData icon;
  final Color circleColor;
  final Color buttonColor;
  final Color tagColor;
  final List<String> tags;

  factory _ModeVisualData.fromMode(BuildContext context, String mode) {
    return switch (mode) {
      'doctor' => _ModeVisualData(
        colors: const [Color(0xFF5B86DB), Color(0xFF4C72C8)],
        icon: Icons.smart_toy_rounded,
        circleColor: const Color(0xFF7EA0E8),
        buttonColor: const Color(0xFF4F78D2),
        tagColor: const Color(0x33FFFFFF),
        tags: [
          _t(context, '认知行为疗法', 'CBT'),
          _t(context, '病情追踪', 'Tracking'),
          _t(context, '任务建议', 'Tasks'),
        ],
      ),
      'patient' => _ModeVisualData(
        colors: const [Color(0xFFFFB24F), Color(0xFFF39C38)],
        icon: Icons.healing_rounded,
        circleColor: const Color(0xFFFFC87E),
        buttonColor: const Color(0xFFF39C38),
        tagColor: const Color(0x33FFFFFF),
        tags: [
          _t(context, '角色演练', 'Role-play'),
          _t(context, '共情训练', 'Empathy'),
          _t(context, '反馈系统', 'Feedback'),
        ],
      ),
      _ => _ModeVisualData(
        colors: const [Color(0xFFF5A497), Color(0xFFE78B81)],
        icon: Icons.volunteer_activism_rounded,
        circleColor: const Color(0xFFF8B8AE),
        buttonColor: const Color(0xFFE78B81),
        tagColor: const Color(0x33FFFFFF),
        tags: [
          _t(context, '情感支持', 'Support'),
          _t(context, '理想伙伴', 'Partner'),
          _t(context, '个性化定制', 'Personalize'),
        ],
      ),
    };
  }
}

String _modeDescription(BuildContext context, String mode) {
  return switch (mode) {
    'doctor' => context.l10n.doctorChatDescription,
    'patient' => context.l10n.patientChatDescription,
    _ => context.l10n.companionChatDescription,
  };
}

String _modeTitle(BuildContext context, String mode) {
  return switch (mode) {
    'doctor' => _t(context, 'AI 心理医生', 'AI doctor'),
    'patient' => _t(context, 'AI 模拟病人', 'AI patient'),
    _ => _t(context, 'AI 心理陪伴', 'AI companion'),
  };
}

Color _modeAccent(String mode) {
  return switch (mode) {
    'doctor' => const Color(0xFF5B86DB),
    'patient' => const Color(0xFFF39C38),
    _ => const Color(0xFFE78B81),
  };
}

String _conversationSubtitle(BuildContext context, ChatSession session) {
  final lastTime = (session.lastMessageTime ?? '').trim();
  if (lastTime.isNotEmpty) {
    return lastTime;
  }
  return _modeTitle(context, session.chatMode);
}

String _planSummaryText(BuildContext context, List<dynamic>? plans) {
  if (plans == null) {
    return '';
  }
  if (plans.isEmpty) {
    return _t(context, '暂无计划', 'No plans');
  }
  return _t(context, '共 ${plans.length} 个阶段', '${plans.length} active plan(s)');
}

String _communityTeaser(BuildContext context, dynamic page) {
  if (page == null) {
    return context.l10n.communityFeedEmpty;
  }
  final list = page.list as List<dynamic>;
  if (list.isEmpty) {
    return context.l10n.communityFeedEmpty;
  }
  final first = list.first;
  return _t(
    context,
    '最新动态来自 ${first.authorName}',
    'Latest community post from ${first.authorName}',
  );
}

void _openSession(BuildContext context, ChatSession session) {
  context.push(
    Uri(
      path: '/chat/session/${session.id}',
      queryParameters: {'mode': session.chatMode, 'title': session.sessionName},
    ).toString(),
  );
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
