import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/chat_controller.dart';
import '../data/chat_models.dart';
import 'chat_launch_sheet.dart';
import 'chat_prompt_config_sheet.dart';

class ChatHomeScreen extends ConsumerWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _ChatHomePalette.of(context);
    final overview = ref.watch(chatOverviewProvider);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(_t(context, 'AI 心理支持', 'AI support')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: overview.when(
          data: (data) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(chatOverviewProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.cardBackground,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: palette.avatarBackground,
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          color: Color(0xFF5B86DB),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.chatTitle,
                              style: TextStyle(
                                color: palette.primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _t(
                                context,
                                '选择适合你当前状态的模式，开始一段真实对话。',
                                'Choose the mode that fits your current state and begin a real conversation.',
                              ),
                              style: TextStyle(
                                color: palette.secondaryText,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final mode in data.modes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ModeCard(
                      mode: mode,
                      onTap: () => _startSession(context, ref, mode),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.recentConversations,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (data.recentSessions.isEmpty)
                  _EmptyState(text: context.l10n.noConversations)
                else
                  ...data.recentSessions.map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SessionTile(session: session),
                    ),
                  ),
              ],
            ),
          ),
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(chatOverviewProvider),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _startSession(
    BuildContext context,
    WidgetRef ref,
    ChatModeInfo mode,
  ) async {
    final chatMode = mode.chatMode;
    final option = chatMode == 'doctor'
        ? ChatLaunchOption.online
        : await showChatLaunchSheet(
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
    final promptReady = await _ensureOnlinePrompt(context, ref, mode);
    if (!promptReady || !context.mounted) {
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

  Future<bool> _ensureOnlinePrompt(
    BuildContext context,
    WidgetRef ref,
    ChatModeInfo mode,
  ) async {
    if (mode.promptText.trim().isNotEmpty) {
      return true;
    }
    final prompt = await showChatPromptConfigSheet(
      context,
      chatMode: mode.chatMode,
      title: _t(context, '设置对话提示词', 'Set chat prompt'),
      initialPrompt: '',
    );
    if (prompt == null || !context.mounted) {
      return false;
    }
    try {
      await ref
          .read(chatRepositoryProvider)
          .saveConfig(chatMode: mode.chatMode, promptText: prompt);
      ref.invalidate(chatOverviewProvider);
      ref.invalidate(chatConfigProvider(mode.chatMode));
      return true;
    } on Object catch (error) {
      if (context.mounted) {
        context.showCenteredNotice(error.toString());
      }
      return false;
    }
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onTap});

  final ChatModeInfo mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _modeVisual(context, mode.chatMode);
    final latest = mode.latestSession;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: visual.$1),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _modeDescription(context, mode.chatMode),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF8F5FF),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final label in visual.$2)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
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
                      ),
                  ],
                ),
                if (latest != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    latest.lastMessage.isNotEmpty
                        ? latest.lastMessage
                        : latest.sessionName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE9EEFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: visual.$3,
                    minimumSize: const Size(170, 46),
                  ),
                  onPressed: onTap,
                  child: Text(_t(context, '开始体验', 'Start')),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(color: visual.$4, shape: BoxShape.circle),
            child: Icon(visual.$5, color: Colors.white, size: 50),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final ChatSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _ChatHomePalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _modeAccent(
            session.chatMode,
          ).withValues(alpha: 0.14),
          child: Icon(
            _modeIcon(session.chatMode),
            color: _modeAccent(session.chatMode),
          ),
        ),
        title: Text(
          session.sessionName,
          style: TextStyle(
            color: palette.primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          session.lastMessage.isEmpty
              ? _modeTitle(context, session.chatMode)
              : session.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: palette.secondaryText),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => _deleteSession(context, ref, session),
        ),
        onTap: () => _openSession(context, session),
      ),
    );
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    ChatSession session,
  ) async {
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = _ChatHomePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}

void _openSession(BuildContext context, ChatSession session) {
  context.push(
    Uri(
      path: '/chat/session/${session.id}',
      queryParameters: {'mode': session.chatMode, 'title': session.sessionName},
    ).toString(),
  );
}

IconData _modeIcon(String mode) {
  return switch (mode) {
    'doctor' => Icons.smart_toy_rounded,
    'patient' => Icons.healing_rounded,
    _ => Icons.volunteer_activism_rounded,
  };
}

Color _modeAccent(String mode) {
  return switch (mode) {
    'doctor' => const Color(0xFF5B86DB),
    'patient' => const Color(0xFFF39C38),
    _ => const Color(0xFFE78B81),
  };
}

String _modeTitle(BuildContext context, String mode) {
  return switch (mode) {
    'doctor' => _t(context, 'AI 心理医生', 'AI doctor'),
    'patient' => _t(context, 'AI 模拟病人', 'AI patient'),
    _ => _t(context, 'AI 心理陪伴', 'AI companion'),
  };
}

String _modeDescription(BuildContext context, String mode) {
  return switch (mode) {
    'doctor' => context.l10n.doctorChatDescription,
    'patient' => context.l10n.patientChatDescription,
    _ => context.l10n.companionChatDescription,
  };
}

(List<Color>, List<String>, Color, Color, IconData) _modeVisual(
  BuildContext context,
  String mode,
) {
  return switch (mode) {
    'doctor' => (
      const [Color(0xFF5B86DB), Color(0xFF4C72C8)],
      [
        _t(context, '认知行为疗法', 'CBT'),
        _t(context, '病情追踪', 'Tracking'),
        _t(context, '任务建议', 'Tasks'),
      ],
      const Color(0xFF4F78D2),
      const Color(0xFF7EA0E8),
      Icons.smart_toy_rounded,
    ),
    'patient' => (
      const [Color(0xFFFFB24F), Color(0xFFF39C38)],
      [
        _t(context, '角色演练', 'Role-play'),
        _t(context, '共情训练', 'Empathy'),
        _t(context, '反馈系统', 'Feedback'),
      ],
      const Color(0xFFF39C38),
      const Color(0xFFFFC87E),
      Icons.healing_rounded,
    ),
    _ => (
      const [Color(0xFFF5A497), Color(0xFFE78B81)],
      [
        _t(context, '情感支持', 'Support'),
        _t(context, '理想伙伴', 'Partner'),
        _t(context, '个性化定制', 'Personalize'),
      ],
      const Color(0xFFE78B81),
      const Color(0xFFF8B8AE),
      Icons.volunteer_activism_rounded,
    ),
  };
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _ChatHomePalette {
  const _ChatHomePalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.avatarBackground,
  });

  factory _ChatHomePalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _ChatHomePalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      avatarBackground: isDark
          ? scheme.primaryContainer.withValues(alpha: 0.28)
          : const Color(0xFFEAF0FF),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color avatarBackground;
}
