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
      backgroundColor: const Color(0xFFF5F6FB),
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
        actions: [
          IconButton.filled(
            tooltip: _t(context, '会话说明', 'About chat'),
            onPressed: () => context.showCenteredNotice(
              _modeDescription(context, widget.chatMode),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: records.when(
                data: (page) =>
                    _RecordList(records: page.list, chatMode: widget.chatMode),
                error: (error, _) => Center(child: Text(error.toString())),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                14 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: context.l10n.chatMessageHint,
                        filled: true,
                        fillColor: const Color(0xFFF4F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: _t(context, '语音输入', 'Voice input'),
                    onPressed: () => context.showCenteredNotice(
                      context.l10n.featureComingSoon,
                    ),
                    icon: const Icon(Icons.mic_none_rounded),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: context.l10n.sendMessage,
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
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
  const _RecordList({required this.records, required this.chatMode});

  final List<ChatRecord> records;
  final String chatMode;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(child: Text(context.l10n.noMessages));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _MessageBubble(record: record, chatMode: chatMode),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.record, required this.chatMode});

  final ChatRecord record;
  final String chatMode;

  @override
  Widget build(BuildContext context) {
    final align = record.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = record.isUser ? const Color(0xFF5B86DB) : Colors.white;
    final textColor = record.isUser ? Colors.white : const Color(0xFF303236);
    final avatarColor = record.isUser
        ? const Color(0xFFF8E3DB)
        : const Color(0xFFEAF0FF);

    return Align(
      alignment: align,
      child: Row(
        mainAxisAlignment: record.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!record.isUser)
            _BubbleAvatar(
              backgroundColor: avatarColor,
              icon: Icons.smart_toy_rounded,
            ),
          if (!record.isUser) const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: record.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if ((record.messageTime ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      record.messageTime!,
                      style: const TextStyle(
                        color: Color(0xFF9AA0A8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: record.isUser
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                  ),
                  child: _RecordContent(record: record, textColor: textColor),
                ),
              ],
            ),
          ),
          if (record.isUser) const SizedBox(width: 10),
          if (record.isUser)
            _BubbleAvatar(
              backgroundColor: avatarColor,
              icon: Icons.person_rounded,
            ),
        ],
      ),
    );
  }
}

class _RecordContent extends StatelessWidget {
  const _RecordContent({required this.record, required this.textColor});

  final ChatRecord record;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    switch (record.contentType) {
      case 'voice':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq_rounded, color: textColor),
            const SizedBox(width: 8),
            Text(
              record.content.isEmpty
                  ? _t(context, '语音消息', 'Voice note')
                  : record.content,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
            ),
          ],
        );
      case 'image':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, color: textColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                record.content,
                style: TextStyle(color: textColor, height: 1.5),
              ),
            ),
          ],
        );
      case 'file':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.attach_file_rounded, color: textColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                record.content,
                style: TextStyle(color: textColor, height: 1.5),
              ),
            ),
          ],
        );
      default:
        return Text(
          record.content,
          style: TextStyle(color: textColor, fontSize: 16, height: 1.6),
        );
    }
  }
}

class _BubbleAvatar extends StatelessWidget {
  const _BubbleAvatar({required this.backgroundColor, required this.icon});

  final Color backgroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: backgroundColor,
      child: Icon(icon, color: const Color(0xFF5B86DB)),
    );
  }
}

String _modeDescription(BuildContext context, String mode) {
  return switch (mode) {
    'doctor' => context.l10n.doctorChatDescription,
    'patient' => context.l10n.patientChatDescription,
    _ => context.l10n.companionChatDescription,
  };
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
