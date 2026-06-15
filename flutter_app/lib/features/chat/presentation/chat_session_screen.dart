import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/chat_controller.dart';
import '../data/chat_models.dart';

class ChatSessionScreen extends ConsumerStatefulWidget {
  const ChatSessionScreen({
    super.key,
    required this.sessionId,
    required this.chatMode,
    required this.title,
  });

  final int sessionId;
  final String chatMode;
  final String title;

  @override
  ConsumerState<ChatSessionScreen> createState() => _ChatSessionScreenState();
}

class _ChatSessionScreenState extends ConsumerState<ChatSessionScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(chatRecordsProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: records.when(
                data: (page) => _RecordList(records: page.list),
                error: (error, _) => Center(child: Text(error.toString())),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: context.l10n.chatMessageHint,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: context.l10n.sendMessage,
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _sending) {
      return;
    }

    setState(() => _sending = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            sessionId: widget.sessionId,
            chatMode: widget.chatMode,
            content: content,
          );
      _controller.clear();
      ref.invalidate(chatRecordsProvider(widget.sessionId));
      ref.invalidate(chatOverviewProvider);
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
}

class _RecordList extends StatelessWidget {
  const _RecordList({required this.records});

  final List<ChatRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(child: Text(context.l10n.noMessages));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Align(
          alignment: record.isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: Card(
              color: record.isUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(record.content),
              ),
            ),
          ),
        );
      },
    );
  }
}
