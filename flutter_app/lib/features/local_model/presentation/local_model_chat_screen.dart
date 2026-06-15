import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/local_llm/llama_engine.dart';
import '../../../core/local_llm/local_chat_store.dart';
import '../../../core/local_llm/local_prompt_resolver.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/local_model_controller.dart';
import '../data/local_model_models.dart';

class LocalModelChatScreen extends ConsumerStatefulWidget {
  const LocalModelChatScreen({
    super.key,
    required this.modelId,
    required this.chatMode,
    required this.title,
  });

  final int modelId;
  final String chatMode;
  final String title;

  @override
  ConsumerState<LocalModelChatScreen> createState() =>
      _LocalModelChatScreenState();
}

class _LocalModelChatScreenState extends ConsumerState<LocalModelChatScreen> {
  final _controller = TextEditingController();
  List<LocalChatMessage> _messages = const [];
  bool _loadingMessages = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadMessages);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(localModelCatalogProvider);
    final promptLocale = Localizations.localeOf(context).toLanguageTag();
    final prompts = ref.watch(localModelPromptsProvider(promptLocale));
    final downloadStates = ref.watch(localModelDownloadControllerProvider);
    final runtimeStatus = ref.watch(llamaRuntimeStatusProvider);
    final runtimeReady = runtimeStatus.hasValue
        ? runtimeStatus.value?.isAvailable == true
        : false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title.isEmpty ? context.l10n.localChat : widget.title,
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.clearLocalChat,
            onPressed: _messages.isEmpty || _sending ? null : _clearMessages,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: catalog.when(
          data: (models) {
            final model = _findModel(models);
            if (model == null) {
              return _CenteredMessage(text: context.l10n.modelUnavailable);
            }

            final states = downloadStates.hasValue
                ? downloadStates.value ?? const <int, LocalModelDownloadState>{}
                : const <int, LocalModelDownloadState>{};
            final state =
                states[model.id] ??
                const LocalModelDownloadState.notDownloaded();
            if (!state.isReady) {
              return _CenteredMessage(text: context.l10n.localModelNotReady);
            }

            return prompts.when(
              data: (items) {
                final prompt = ref
                    .read(localPromptResolverProvider)
                    .resolve(
                      modelId: model.id,
                      chatMode: widget.chatMode,
                      locale: promptLocale,
                      prompts: items,
                    );
                return Column(
                  children: [
                    _RuntimeBanner(status: runtimeStatus),
                    Expanded(
                      child: _LocalMessageList(
                        loading: _loadingMessages,
                        messages: _messages,
                        firstMessage: prompt.firstMessage,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              enabled: !_sending && runtimeReady,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: context.l10n.localModelMessageHint,
                                border: const OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _send(model, state, prompt),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: context.l10n.sendMessage,
                            onPressed: _sending || !runtimeReady
                                ? null
                                : () => _send(model, state, prompt),
                            icon: _sending
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              error: (error, _) => _CenteredMessage(text: error.toString()),
              loading: () => const Center(child: CircularProgressIndicator()),
            );
          },
          error: (error, _) => _CenteredMessage(text: error.toString()),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  LocalModelItem? _findModel(List<LocalModelItem> models) {
    for (final model in models) {
      if (model.id == widget.modelId) {
        return model;
      }
    }
    return null;
  }

  Future<void> _loadMessages() async {
    final memberId = await _memberId();
    final messages = await ref
        .read(localChatStoreProvider)
        .readMessages(
          memberId: memberId,
          modelId: widget.modelId,
          chatMode: widget.chatMode,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _messages = messages;
      _loadingMessages = false;
    });
  }

  Future<void> _send(
    LocalModelItem model,
    LocalModelDownloadState state,
    ResolvedLocalPrompt prompt,
  ) async {
    final content = _controller.text.trim();
    if (content.isEmpty || _sending) {
      return;
    }

    final unavailableMessage = context.l10n.localModelRuntimeUnavailable;
    setState(() => _sending = true);
    try {
      final runtime = await ref.read(llamaRuntimeStatusProvider.future);
      if (!runtime.isAvailable) {
        throw StateError('$unavailableMessage ${runtime.errorMessage}');
      }
      final memberId = await _memberId();
      final history = await ref
          .read(localChatStoreProvider)
          .readMessages(
            memberId: memberId,
            modelId: model.id,
            chatMode: widget.chatMode,
          );
      final reply = await ref
          .read(llamaEngineProvider)
          .generate(
            model: model,
            modelPath: state.filePath,
            systemPrompt: prompt.systemPrompt,
            history: history,
            userMessage: content,
          );
      await ref
          .read(localChatStoreProvider)
          .appendPair(
            memberId: memberId,
            modelId: model.id,
            chatMode: widget.chatMode,
            userContent: content,
            assistantContent: reply,
          );
      _controller.clear();
      await _loadMessages();
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _clearMessages() async {
    final memberId = await _memberId();
    await ref
        .read(localChatStoreProvider)
        .clearMessages(
          memberId: memberId,
          modelId: widget.modelId,
          chatMode: widget.chatMode,
        );
    if (!mounted) {
      return;
    }
    setState(() => _messages = const []);
  }

  Future<String> _memberId() async {
    return await ref.read(tokenStorageProvider).readMemberId() ?? 'anonymous';
  }
}

class _RuntimeBanner extends StatelessWidget {
  const _RuntimeBanner({required this.status});

  final AsyncValue<LlamaRuntimeStatus> status;

  @override
  Widget build(BuildContext context) {
    return status.when(
      data: (runtime) {
        if (runtime.isAvailable) {
          return _InlineStatus(
            icon: Icons.check_circle_outline,
            text:
                '${context.l10n.localModelRuntimeReady} '
                '${runtime.libraryPath}',
            severity: _InlineStatusSeverity.success,
          );
        }
        return _InlineStatus(
          icon: Icons.error_outline,
          text: [
            '${context.l10n.localModelRuntimeUnavailable} '
                '${runtime.libraryPath}',
            runtime.errorMessage,
          ].where((line) => line.trim().isNotEmpty).join('\n'),
          severity: _InlineStatusSeverity.error,
        );
      },
      error: (error, _) => _InlineStatus(
        icon: Icons.error_outline,
        text: '${context.l10n.localModelRuntimeUnavailable} $error',
        severity: _InlineStatusSeverity.error,
      ),
      loading: () => _InlineStatus(
        icon: Icons.sync,
        text: context.l10n.localModelRuntimeChecking,
        severity: _InlineStatusSeverity.info,
      ),
    );
  }
}

enum _InlineStatusSeverity { info, success, error }

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({
    required this.icon,
    required this.text,
    required this.severity,
  });

  final IconData icon;
  final String text;
  final _InlineStatusSeverity severity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (severity) {
      _InlineStatusSeverity.success => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      _InlineStatusSeverity.error => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      _ => (colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalMessageList extends StatelessWidget {
  const _LocalMessageList({
    required this.loading,
    required this.messages,
    required this.firstMessage,
  });

  final bool loading;
  final List<LocalChatMessage> messages;
  final String firstMessage;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleMessages = [
      if (messages.isEmpty && firstMessage.isNotEmpty)
        LocalChatMessage(
          role: 'assistant',
          content: firstMessage,
          createdAt: DateTime.now(),
        ),
      ...messages,
    ];
    if (visibleMessages.isEmpty) {
      return Center(child: Text(context.l10n.noMessages));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visibleMessages.length,
      itemBuilder: (context, index) {
        final message = visibleMessages[index];
        final isUser = message.role == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: Card(
              color: isUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(message.content),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
