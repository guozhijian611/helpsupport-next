import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';
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
  final Set<int> _expandedVoiceTextIds = <int>{};
  Timer? _recordingTicker;
  Duration _recordingElapsed = Duration.zero;
  DateTime? _recordingStartedAt;
  bool _sending = false;
  bool _voiceComposer = false;
  bool _recording = false;
  bool _callActive = false;
  bool _callVideoEnabled = false;

  bool get _supportsDoctorCall => widget.chatMode == 'doctor';

  @override
  void dispose() {
    _recordingTicker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _ChatSessionPalette.of(context);
    final records = ref.watch(chatRecordsProvider(widget.sessionId));
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final apiClient = ref.watch(apiClientProvider);
    final userAvatarUrl = _resolveUserAvatar(session, apiClient.resolveUrl);

    return WillPopScope(
      onWillPop: () async {
        if (_callActive) {
          await _confirmEndCall();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: palette.pageBackground,
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: Text(_appBarTitle(records.asData?.value.list ?? const [])),
          actions: _supportsDoctorCall
              ? [
                  _TopModeButton(
                    active: !_callActive,
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () {
                      if (_callActive) {
                        setState(() => _callActive = false);
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  _TopModeButton(
                    active: _callActive,
                    icon: Icons.call_outlined,
                    onTap: _callActive ? null : _confirmStartCall,
                  ),
                  const SizedBox(width: 18),
                ]
              : [
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _callActive
                ? _DoctorCallView(
                    key: const ValueKey('doctor-call-view'),
                    avatarUrl: userAvatarUrl,
                    videoEnabled: _callVideoEnabled,
                    onBackToMessages: () => setState(() => _callActive = false),
                    onEndCall: _confirmEndCall,
                    onToggleVideo: () =>
                        setState(() => _callVideoEnabled = !_callVideoEnabled),
                  )
                : Column(
                    key: const ValueKey('chat-message-view'),
                    children: [
                      if (_conversationTime(
                        records.asData?.value.list ?? const [],
                      ).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 2),
                          child: Text(
                            _conversationTime(
                              records.asData?.value.list ?? const [],
                            ),
                            style: TextStyle(
                              color: palette.secondaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Expanded(
                        child: records.when(
                          data: (page) => _RecordList(
                            records: page.list,
                            chatMode: widget.chatMode,
                            userAvatarUrl: userAvatarUrl,
                            expandedVoiceTextIds: _expandedVoiceTextIds,
                            onToggleTranscript: _toggleTranscript,
                            onRecordActions: _openRecordActions,
                          ),
                          error: (error, _) =>
                              Center(child: Text(error.toString())),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      _ChatComposer(
                        voiceComposer: _voiceComposer,
                        recording: _recording,
                        sending: _sending,
                        controller: _controller,
                        voiceDurationLabel: _voiceDurationLabel,
                        onSubmitted: _send,
                        onToggleVoiceComposer: () =>
                            setState(() => _voiceComposer = !_voiceComposer),
                        onLongPressStart: _startVoiceRecording,
                        onLongPressEnd: _finishVoiceRecording,
                        onLongPressCancel: _cancelVoiceRecording,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String get _voiceDurationLabel {
    final seconds = math.max(1, _recordingElapsed.inSeconds);
    return '$seconds\'\'';
  }

  String _appBarTitle(List<ChatRecord> records) {
    return widget.title.trim().isEmpty
        ? _modeTitle(context, widget.chatMode)
        : widget.title;
  }

  Future<void> _handleBack() async {
    if (_callActive) {
      await _confirmEndCall();
      return;
    }
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _confirmStartCall() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: _t(context, '视频通话', 'Video call'),
        message: _t(
          context,
          '与AI心理医生进行语音通话？',
          'Start a voice call with the AI doctor?',
        ),
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _callActive = true;
        _callVideoEnabled = false;
      });
    }
  }

  Future<void> _confirmEndCall() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: _t(context, '结束', 'End'),
        message: _t(
          context,
          '是否结束本次对话？',
          'Do you want to end this conversation?',
        ),
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _callActive = false;
        _callVideoEnabled = false;
      });
    }
  }

  void _startVoiceRecording() {
    if (_recording || _sending) {
      return;
    }
    _recordingTicker?.cancel();
    setState(() {
      _voiceComposer = true;
      _recording = true;
      _recordingElapsed = const Duration(seconds: 1);
      _recordingStartedAt = DateTime.now();
    });
    _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _recordingStartedAt;
      if (startedAt == null || !mounted) {
        return;
      }
      setState(() {
        _recordingElapsed = DateTime.now().difference(startedAt);
      });
    });
  }

  Future<void> _finishVoiceRecording() async {
    if (!_recording) {
      return;
    }
    final seconds = math.max(
      1,
      (_recordingStartedAt == null
              ? _recordingElapsed
              : DateTime.now().difference(_recordingStartedAt!))
          .inSeconds,
    );
    _stopRecordingState();
    try {
      await ref
          .read(chatRepositoryProvider)
          .saveUserRecord(
            sessionId: widget.sessionId,
            content: '$seconds\'\'',
            contentType: 'voice',
          );
      ref.invalidate(chatRecordsProvider(widget.sessionId));
      ref.invalidate(chatOverviewProvider);
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    }
  }

  void _cancelVoiceRecording() {
    if (!_recording) {
      return;
    }
    _stopRecordingState();
  }

  void _stopRecordingState() {
    _recordingTicker?.cancel();
    if (mounted) {
      setState(() {
        _recording = false;
        _recordingStartedAt = null;
        _recordingElapsed = Duration.zero;
      });
    } else {
      _recording = false;
      _recordingStartedAt = null;
      _recordingElapsed = Duration.zero;
    }
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

  void _toggleTranscript(ChatRecord record) {
    if (!_hasTranscript(record)) {
      context.showCenteredNotice(
        _t(
          context,
          '当前语音消息暂无转文字结果',
          'No transcript is available for this voice message yet.',
        ),
      );
      return;
    }
    setState(() {
      if (!_expandedVoiceTextIds.add(record.id)) {
        _expandedVoiceTextIds.remove(record.id);
      }
    });
  }

  Future<void> _openRecordActions(ChatRecord record) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: _t(context, '消息操作', 'Message actions'),
      barrierColor: Colors.transparent,
      pageBuilder: (context, _, __) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: _RecordActionMenu(
                onDismiss: () => Navigator.of(context).pop(),
                onCopy: () async {
                  await Clipboard.setData(ClipboardData(text: record.content));
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    context.showCenteredNotice(
                      _t(context, '已复制消息内容', 'Message copied'),
                    );
                  }
                },
                onRetract: () {
                  Navigator.of(context).pop();
                  context.showCenteredNotice(
                    _t(
                      context,
                      '当前会话页暂未接入撤回能力',
                      'Recall is not connected on this screen yet.',
                    ),
                  );
                },
                onDelete: () {
                  Navigator.of(context).pop();
                  context.showCenteredNotice(
                    _t(
                      context,
                      '当前会话页暂未接入删除能力',
                      'Delete is not connected on this screen yet.',
                    ),
                  );
                },
                onShare: () async {
                  await Clipboard.setData(ClipboardData(text: record.content));
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    context.showCenteredNotice(
                      _t(
                        context,
                        '已复制消息内容，可继续分享',
                        'Message copied and ready to share.',
                      ),
                    );
                  }
                },
                onTranscribe: () {
                  Navigator.of(context).pop();
                  _toggleTranscript(record);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopModeButton extends StatelessWidget {
  const _TopModeButton({
    required this.active,
    required this.icon,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _ChatSessionPalette.of(context);
    return IconButton.filledTonal(
      onPressed: onTap,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(54),
        backgroundColor: active
            ? palette.activeButtonBackground
            : palette.cardBackground,
        foregroundColor: active
            ? palette.activeButtonForeground
            : palette.primaryText,
      ),
      icon: Icon(icon),
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.records,
    required this.chatMode,
    required this.userAvatarUrl,
    required this.expandedVoiceTextIds,
    required this.onToggleTranscript,
    required this.onRecordActions,
  });

  final List<ChatRecord> records;
  final String chatMode;
  final String userAvatarUrl;
  final Set<int> expandedVoiceTextIds;
  final ValueChanged<ChatRecord> onToggleTranscript;
  final ValueChanged<ChatRecord> onRecordActions;

  @override
  Widget build(BuildContext context) {
    final palette = _ChatSessionPalette.of(context);
    if (records.isEmpty) {
      return Center(child: Text(context.l10n.noMessages));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _MessageBubble(
            record: record,
            chatMode: chatMode,
            userAvatarUrl: userAvatarUrl,
            transcriptExpanded: expandedVoiceTextIds.contains(record.id),
            onToggleTranscript: () => onToggleTranscript(record),
            onLongPress: () => onRecordActions(record),
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.record,
    required this.chatMode,
    required this.userAvatarUrl,
    required this.transcriptExpanded,
    required this.onToggleTranscript,
    required this.onLongPress,
  });

  final ChatRecord record;
  final String chatMode;
  final String userAvatarUrl;
  final bool transcriptExpanded;
  final VoidCallback onToggleTranscript;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = _ChatSessionPalette.of(context);
    final isVoice = record.contentType == 'voice';
    final align = record.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = record.isUser
        ? palette.userBubbleBackground
        : palette.cardBackground;
    final textColor = record.isUser
        ? palette.userBubbleForeground
        : palette.primaryText;
    final avatarColor = record.isUser
        ? palette.userAvatarBackground
        : palette.assistantAvatarBackground;

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
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: record.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if ((record.messageTime ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _messageTimeText(record.messageTime!),
                        style: TextStyle(
                          color: palette.secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.76,
                    ),
                    padding: isVoice
                        ? const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          )
                        : const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: record.isUser
                          ? null
                          : [
                              BoxShadow(
                                color: palette.shadowColor,
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                    ),
                    child: isVoice
                        ? _VoiceRecordRow(
                            record: record,
                            textColor: textColor,
                            onToggleTranscript: onToggleTranscript,
                          )
                        : _RecordContent(record: record, textColor: textColor),
                  ),
                  if (transcriptExpanded && _hasTranscript(record)) ...[
                    const SizedBox(height: 10),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.76,
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: palette.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: palette.shadowColor.withValues(alpha: 0.8),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        record.content,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onToggleTranscript,
                      child: Text(
                        _t(context, '收起', 'Collapse'),
                        style: TextStyle(
                          color: palette.secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (record.isUser) const SizedBox(width: 10),
          if (record.isUser)
            _BubbleAvatar(
              backgroundColor: avatarColor,
              icon: Icons.person_rounded,
              imageUrl: userAvatarUrl,
            ),
        ],
      ),
    );
  }
}

class _VoiceRecordRow extends StatelessWidget {
  const _VoiceRecordRow({
    required this.record,
    required this.textColor,
    required this.onToggleTranscript,
  });

  final ChatRecord record;
  final Color textColor;
  final VoidCallback onToggleTranscript;

  @override
  Widget build(BuildContext context) {
    final palette = _ChatSessionPalette.of(context);
    if (record.isUser) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _voiceDisplayText(record.content),
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.wifi_tethering_rounded, color: textColor, size: 22),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.multitrack_audio_rounded, color: textColor, size: 22),
        const SizedBox(width: 10),
        Text(
          _voiceDisplayText(record.content),
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 18),
        GestureDetector(
          onTap: onToggleTranscript,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: palette.voiceActionBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              size: 18,
              color: palette.voiceActionForeground,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const SizedBox(
          width: 10,
          height: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFFF5A5A),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
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
  const _BubbleAvatar({
    required this.backgroundColor,
    required this.icon,
    this.imageUrl = '',
  });

  final Color backgroundColor;
  final IconData icon;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final palette = _ChatSessionPalette.of(context);
    if (imageUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: backgroundColor,
        foregroundImage: NetworkImage(imageUrl),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: backgroundColor,
      child: Icon(icon, color: palette.avatarIcon),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.voiceComposer,
    required this.recording,
    required this.sending,
    required this.controller,
    required this.voiceDurationLabel,
    required this.onSubmitted,
    required this.onToggleVoiceComposer,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onLongPressCancel,
  });

  final bool voiceComposer;
  final bool recording;
  final bool sending;
  final TextEditingController controller;
  final String voiceDurationLabel;
  final VoidCallback onSubmitted;
  final VoidCallback onToggleVoiceComposer;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final VoidCallback onLongPressCancel;

  @override
  Widget build(BuildContext context) {
    final palette = _ChatSessionPalette.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: voiceComposer
          ? Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onLongPressStart: (_) => onLongPressStart(),
                    onLongPressEnd: (_) => onLongPressEnd(),
                    onLongPressCancel: onLongPressCancel,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 56,
                      decoration: BoxDecoration(
                        color: recording
                            ? palette.activeButtonBackground
                            : palette.softSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        recording
                            ? _t(context, '松开 发送', 'Release to send')
                            : _t(context, '按住 说话', 'Hold to talk'),
                        style: TextStyle(
                          color: recording
                              ? palette.activeButtonForeground
                              : palette.primaryText,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: _t(context, '切换文字输入', 'Switch to text input'),
                  onPressed: onToggleVoiceComposer,
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(54),
                    backgroundColor: palette.softSurface,
                    foregroundColor: palette.primaryText,
                  ),
                  icon: Icon(
                    recording
                        ? Icons.radio_button_checked_rounded
                        : Icons.dialpad_rounded,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !sending,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: context.l10n.chatMessageHint,
                      filled: true,
                      fillColor: palette.softSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => onSubmitted(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: _t(context, '语音输入', 'Voice input'),
                  onPressed: onToggleVoiceComposer,
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(54),
                    backgroundColor: palette.softSurface,
                    foregroundColor: palette.primaryText,
                  ),
                  icon: const Icon(Icons.mic_none_rounded),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  tooltip: context.l10n.sendMessage,
                  onPressed: sending ? null : onSubmitted,
                  icon: sending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
    );
  }
}

class _DoctorCallView extends StatelessWidget {
  const _DoctorCallView({
    super.key,
    required this.avatarUrl,
    required this.videoEnabled,
    required this.onBackToMessages,
    required this.onEndCall,
    required this.onToggleVideo,
  });

  final String avatarUrl;
  final bool videoEnabled;
  final VoidCallback onBackToMessages;
  final VoidCallback onEndCall;
  final VoidCallback onToggleVideo;

  @override
  Widget build(BuildContext context) {
    final palette = _ChatSessionPalette.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: palette.callBackground),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _CallRingPainter())),
        if (videoEnabled)
          Positioned(
            top: 26,
            right: 18,
            child: _CallPreviewCard(avatarUrl: avatarUrl),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CallCircleButton(
                size: 126,
                color: const Color(0xFFED3E3E),
                iconColor: Colors.white,
                icon: Icons.call_end_rounded,
                onTap: onEndCall,
              ),
              const SizedBox(width: 34),
              _CallCircleButton(
                size: 92,
                color: palette.cardBackground,
                iconColor: palette.primaryText,
                icon: videoEnabled
                    ? Icons.videocam_rounded
                    : Icons.videocam_outlined,
                onTap: onToggleVideo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CallPreviewCard extends StatelessWidget {
  const _CallPreviewCard({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final palette = _ChatSessionPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 202,
        height: 288,
        decoration: BoxDecoration(color: palette.previewBackground),
        child: Stack(
          children: [
            Positioned.fill(
              child: avatarUrl.trim().isNotEmpty
                  ? Image.network(avatarUrl, fit: BoxFit.cover)
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: palette.previewGradient,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 120,
                        color: palette.secondaryText.withValues(alpha: 0.72),
                      ),
                    ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.open_in_full_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallCircleButton extends StatelessWidget {
  const _CallCircleButton({
    required this.size,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  });

  final double size;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: size * 0.34),
      ),
    );
  }
}

class _CallRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x66D37CFF), Color(0x3384B6FF), Color(0x00000000)],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.34))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    canvas.drawCircle(center, size.width * 0.24, glowPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    for (final item in <(double, Color)>[
      (size.width * 0.24, const Color(0x66A07BFF)),
      (size.width * 0.28, const Color(0x66A0C7FF)),
      (size.width * 0.31, const Color(0x55F07EFF)),
      (size.width * 0.34, const Color(0x44E589FF)),
    ]) {
      ringPaint.color = item.$2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: item.$1),
        math.pi * 0.8,
        math.pi * 1.25,
        false,
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RecordActionMenu extends StatelessWidget {
  const _RecordActionMenu({
    required this.onDismiss,
    required this.onRetract,
    required this.onCopy,
    required this.onDelete,
    required this.onShare,
    required this.onTranscribe,
  });

  final VoidCallback onDismiss;
  final VoidCallback onRetract;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onTranscribe;

  @override
  Widget build(BuildContext context) {
    final palette = _ChatSessionPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: palette.actionMenuBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RecordActionItem(
            icon: Icons.undo_rounded,
            label: _t(context, '撤回', 'Retract'),
            onTap: onRetract,
          ),
          _RecordActionItem(
            icon: Icons.copy_all_rounded,
            label: _t(context, '复制', 'Copy'),
            onTap: onCopy,
          ),
          _RecordActionItem(
            icon: Icons.delete_outline_rounded,
            label: _t(context, '删除', 'Delete'),
            onTap: onDelete,
          ),
          _RecordActionItem(
            icon: Icons.open_in_new_rounded,
            label: _t(context, '分享', 'Share'),
            onTap: onShare,
          ),
          _RecordActionItem(
            icon: Icons.translate_rounded,
            label: _t(context, '转文字', 'Transcript'),
            onTap: onTranscribe,
          ),
        ],
      ),
    );
  }
}

class _RecordActionItem extends StatelessWidget {
  const _RecordActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = _ChatSessionPalette.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              child: Column(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.outline),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(74),
                      foregroundColor: palette.secondaryText,
                    ),
                    child: Text(_t(context, '取消', 'Cancel')),
                  ),
                ),
                Container(width: 1, height: 46, color: palette.outline),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(74),
                      foregroundColor: palette.primaryText,
                    ),
                    child: Text(
                      _t(context, '确认', 'Confirm'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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

String _conversationTime(List<ChatRecord> records) {
  for (final record in records) {
    final raw = (record.messageTime ?? '').trim();
    if (raw.isEmpty) {
      continue;
    }
    return _messageTimeText(raw);
  }
  return '';
}

String _messageTimeText(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 16) {
    return trimmed.substring(11, 16);
  }
  return trimmed;
}

String _voiceDisplayText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '60\'\'';
  }
  return trimmed;
}

String _resolveUserAvatar(
  AuthSession? session,
  String Function(String value) resolveUrl,
) {
  final member = session?.member ?? const <String, dynamic>{};
  final avatar = (member['avatar'] ?? '').toString().trim();
  if (avatar.isEmpty) {
    return '';
  }
  return resolveUrl(avatar);
}

bool _hasTranscript(ChatRecord record) {
  if (record.contentType != 'voice') {
    return false;
  }
  final trimmed = record.content.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  if (RegExp(r"^\d+\s*(?:''|″|”|秒)$").hasMatch(trimmed)) {
    return false;
  }
  return true;
}

class _ChatSessionPalette {
  const _ChatSessionPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softSurface,
    required this.primaryText,
    required this.secondaryText,
    required this.outline,
    required this.shadowColor,
    required this.activeButtonBackground,
    required this.activeButtonForeground,
    required this.userBubbleBackground,
    required this.userBubbleForeground,
    required this.userAvatarBackground,
    required this.assistantAvatarBackground,
    required this.avatarIcon,
    required this.voiceActionBackground,
    required this.voiceActionForeground,
    required this.callBackground,
    required this.previewBackground,
    required this.previewGradient,
    required this.actionMenuBackground,
  });

  static _ChatSessionPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _ChatSessionPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      softSurface: scheme.surfaceContainerLow,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      outline: scheme.outlineVariant,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.28)
          : const Color(0x12000000),
      activeButtonBackground: const Color(0xFF5A81DA),
      activeButtonForeground: Colors.white,
      userBubbleBackground: isDark
          ? const Color(0xFF4E73B8)
          : const Color(0xFF5B86DB),
      userBubbleForeground: Colors.white,
      userAvatarBackground: isDark
          ? const Color(0xFF5A3C39)
          : const Color(0xFFF8E3DB),
      assistantAvatarBackground: isDark
          ? scheme.surfaceContainerHighest
          : const Color(0xFFEAF0FF),
      avatarIcon: isDark ? scheme.tertiary : const Color(0xFF5B86DB),
      voiceActionBackground: isDark
          ? scheme.surfaceContainerHighest
          : const Color(0xFFD9E3FA),
      voiceActionForeground: isDark ? scheme.tertiary : const Color(0xFF7C9ADB),
      callBackground: isDark
          ? const Color(0xFF1D2533)
          : const Color(0xFFEAF1FF),
      previewBackground: isDark
          ? const Color(0xFF2A3444)
          : const Color(0xFFD9E1EF),
      previewGradient: isDark
          ? const [Color(0xFF334157), Color(0xFF202A39)]
          : const [Color(0xFFE4EBF6), Color(0xFFC5D3E8)],
      actionMenuBackground: isDark
          ? scheme.surfaceContainerHighest
          : const Color(0xFF454545),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softSurface;
  final Color primaryText;
  final Color secondaryText;
  final Color outline;
  final Color shadowColor;
  final Color activeButtonBackground;
  final Color activeButtonForeground;
  final Color userBubbleBackground;
  final Color userBubbleForeground;
  final Color userAvatarBackground;
  final Color assistantAvatarBackground;
  final Color avatarIcon;
  final Color voiceActionBackground;
  final Color voiceActionForeground;
  final Color callBackground;
  final Color previewBackground;
  final List<Color> previewGradient;
  final Color actionMenuBackground;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
