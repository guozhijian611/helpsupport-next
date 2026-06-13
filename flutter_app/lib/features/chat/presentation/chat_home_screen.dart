import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../application/chat_controller.dart';
import '../data/chat_models.dart';

class ChatHomeScreen extends ConsumerWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(chatOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.chatTitle)),
      body: SafeArea(
        child: overview.when(
          data: (data) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(chatOverviewProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final mode in data.modes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ModeCard(
                      mode: mode,
                      onTap: () => _startSession(context, ref, mode.chatMode),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.recentConversations,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (data.recentSessions.isEmpty)
                  _EmptyState(text: context.l10n.noConversations)
                else
                  for (final session in data.recentSessions)
                    _SessionTile(session: session),
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
    String chatMode,
  ) async {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onTap});

  final ChatModeInfo mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final latest = mode.latestSession;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(_modeIcon(mode.chatMode), color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _modeTitle(context, mode.chatMode),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latest?.lastMessage.isNotEmpty == true
                          ? latest!.lastMessage
                          : _modeDescription(context, mode.chatMode),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_modeIcon(session.chatMode)),
      title: Text(session.sessionName),
      subtitle: Text(
        session.lastMessage.isEmpty
            ? _modeTitle(context, session.chatMode)
            : session.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openSession(context, session),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
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
    'doctor' => Icons.medical_services_outlined,
    'patient' => Icons.assignment_ind_outlined,
    _ => Icons.favorite_outline,
  };
}

String _modeTitle(BuildContext context, String mode) {
  return switch (mode) {
    'doctor' => context.l10n.doctorChatMode,
    'patient' => context.l10n.patientChatMode,
    _ => context.l10n.companionChatMode,
  };
}

String _modeDescription(BuildContext context, String mode) {
  return switch (mode) {
    'doctor' => context.l10n.doctorChatDescription,
    'patient' => context.l10n.patientChatDescription,
    _ => context.l10n.companionChatDescription,
  };
}
