import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image_lib;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/cache/cached_remote_image.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';
import '../application/chat_controller.dart';
import '../data/chat_models.dart';
import 'chat_prompt_config_sheet.dart';

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

class _ChatSessionScreenState extends ConsumerState<ChatSessionScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _callRecorder = AudioRecorder();
  final _callAudioPlayer = AudioPlayer();
  final Set<int> _expandedVoiceTextIds = <int>{};
  StreamSubscription<ChatStreamEvent>? _streamSubscription;
  StreamSubscription<Uint8List>? _callAudioSubscription;
  Timer? _streamSyncTimer;
  Timer? _recordingTicker;
  Timer? _callPingTimer;
  Timer? _callDebugTicker;
  Timer? _callAudioWatchdogTimer;
  Timer? _callTurnCommitTimer;
  Timer? _callTurnMaxCommitTimer;
  Timer? _callResponseTimeoutTimer;
  Duration _recordingElapsed = Duration.zero;
  DateTime? _recordingStartedAt;
  DateTime? _callStartedAt;
  DateTime? _callLastVideoFrameAt;
  DateTime? _callPendingAudioTurnStartedAt;
  WebSocket? _callSocket;
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = const <CameraDescription>[];
  bool _cameraInitializing = false;
  String? _cameraErrorMessage;
  bool _sending = false;
  bool _voiceComposer = false;
  bool _recording = false;
  bool _callActive = false;
  bool _callVideoEnabled = false;
  bool _callMuted = false;
  bool _callSubtitlesEnabled = false;
  bool _callFlashEnabled = false;
  bool _callUsingFrontCamera = true;
  bool _callConnecting = false;
  bool _callConnected = false;
  bool _callUpstreamReady = false;
  bool _callRecording = false;
  bool _callCapturingFrame = false;
  bool _callAudioReadyForFrame = false;
  bool _callPendingAudioTurn = false;
  bool _callResponseActive = false;
  bool _callDebugOverlayExpanded = true;
  bool _promptGateShown = false;
  String _callStatusMessage = '';
  String _callLastRealtimeEvent = '';
  String _callLastRealtimeError = '';
  String _callAssistantText = '';
  final List<Uint8List> _callOutputPcmChunks = <Uint8List>[];
  final Queue<List<Uint8List>> _callAudioPlaybackQueue =
      Queue<List<Uint8List>>();
  final Set<String> _callSavedUserTranscriptIds = <String>{};
  List<ChatRecord> _streamingRecords = const <ChatRecord>[];
  int _sendGeneration = 0;
  int _callSentAudioChunks = 0;
  int _callSentVideoFrames = 0;
  int _callPlayedAudioSegments = 0;
  bool _callPlayingRealtimeAudio = false;

  bool get _supportsDoctorCall => widget.chatMode == 'doctor';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _streamSyncTimer?.cancel();
    unawaited(_streamSubscription?.cancel() ?? Future<void>.value());
    unawaited(_stopRealtimeCall());
    _recordingTicker?.cancel();
    _stopCallDebugTicker();
    _stopCallAudioWatchdog();
    _stopCallResponseTimeoutTimer();
    unawaited(_disposeCallCamera());
    unawaited(_callRecorder.dispose());
    unawaited(_callAudioPlayer.dispose());
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !_callActive || !_callVideoEnabled) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      unawaited(_disposeCallCamera());
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_ensureCallCameraReady(forceReinitialize: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _ChatSessionPalette.of(context);
    final records = ref.watch(chatRecordsProvider(widget.sessionId));
    final promptConfig = widget.chatMode == 'doctor'
        ? null
        : ref.watch(chatConfigProvider(widget.chatMode));
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final apiClient = ref.watch(apiClientProvider);
    final userAvatarUrl = _resolveUserAvatar(session, apiClient.resolveUrl);
    final robotProfiles = ref.watch(aiRobotProfilesProvider('online'));
    final robotProfile = _robotProfileFor(
      widget.chatMode,
      'online',
      robotProfiles.asData?.value,
    );
    final assistantAvatarUrl = _resolveRobotAvatar(
      context,
      robotProfile,
      apiClient.resolveUrl,
    );

    return WillPopScope(
      onWillPop: () async {
        if (_callActive) {
          await _confirmEndCall();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: _callActive ? Colors.black : palette.pageBackground,
        appBar: _callActive
            ? null
            : AppBar(
                centerTitle: true,
                leading: IconButton(
                  onPressed: _handleBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                title: Text(
                  _appBarTitle(records.asData?.value.list ?? const []),
                ),
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
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _callActive
              ? _DoctorCallView(
                  key: const ValueKey('doctor-call-view'),
                  videoEnabled: _callVideoEnabled,
                  cameraController: _cameraController,
                  cameraInitializing: _cameraInitializing,
                  cameraErrorMessage: _cameraErrorMessage,
                  muted: _callMuted,
                  subtitlesEnabled: _callSubtitlesEnabled,
                  connecting: _callConnecting,
                  connected: _callConnected,
                  upstreamReady: _callUpstreamReady,
                  recording: _callRecording,
                  statusMessage: _callStatusMessage,
                  assistantText: _callAssistantText,
                  debugLines: _callDebugLines(),
                  debugExpanded: _callDebugOverlayExpanded,
                  flashEnabled: _callFlashEnabled,
                  usingFrontCamera: _callUsingFrontCamera,
                  onBackToMessages: _dismissCallView,
                  onEndCall: _confirmEndCall,
                  onToggleVideo: () => unawaited(_toggleCallVideo()),
                  onToggleMute: _toggleCallMute,
                  onToggleSubtitles: () => setState(
                    () => _callSubtitlesEnabled = !_callSubtitlesEnabled,
                  ),
                  onToggleDebug: () => setState(
                    () =>
                        _callDebugOverlayExpanded = !_callDebugOverlayExpanded,
                  ),
                  onToggleFlash: () => unawaited(_toggleCallFlash()),
                  onFlipCamera: () => unawaited(_flipCallCamera()),
                )
              : SafeArea(
                  child: Column(
                    key: const ValueKey('chat-message-view'),
                    children: [
                      if (promptConfig != null)
                        promptConfig.when(
                          data: (config) {
                            final prompt = config?.promptText.trim() ?? '';
                            _scheduleOnlinePromptGate(prompt);
                            return ChatPromptSummaryBar(
                              label: _t(context, '对话提示词', 'Chat prompt'),
                              prompt: prompt,
                              onEdit: () => _editOnlinePrompt(prompt),
                            );
                          },
                          error: (error, _) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                            child: Text(
                              error.toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: palette.secondaryText),
                            ),
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        ),
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
                            records: _visibleRecords(page.list),
                            controller: _scrollController,
                            chatMode: widget.chatMode,
                            userAvatarUrl: userAvatarUrl,
                            assistantAvatarUrl: assistantAvatarUrl,
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

  Future<void> _dismissCallView() async {
    await _stopRealtimeCall();
    await _disposeCallCamera();
    if (!mounted) {
      return;
    }
    setState(() {
      _callActive = false;
      _callVideoEnabled = false;
      _callMuted = false;
      _callSubtitlesEnabled = false;
      _callFlashEnabled = false;
      _callUsingFrontCamera = true;
      _callConnecting = false;
      _callConnected = false;
      _callUpstreamReady = false;
      _callRecording = false;
      _callResponseActive = false;
      _callDebugOverlayExpanded = true;
      _callStatusMessage = '';
      _callLastRealtimeEvent = '';
      _callLastRealtimeError = '';
      _callAssistantText = '';
      _cameraInitializing = false;
      _cameraErrorMessage = null;
    });
  }

  Future<void> _confirmStartCall() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: _t(context, '视频通话', 'Video call'),
        message: _t(
          context,
          '与 AI 心理医生开始视频通话？',
          'Start a video call with the AI doctor?',
        ),
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _callActive = true;
        _callVideoEnabled = true;
        _callMuted = false;
        _callSubtitlesEnabled = true;
        _callFlashEnabled = false;
        _callUsingFrontCamera = true;
        _cameraErrorMessage = null;
      });
      _startCallDebugTicker();
      await _ensureCallCameraReady();
      await _startRealtimeCall();
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
      await _stopRealtimeCall();
      await _disposeCallCamera();
      if (!mounted) {
        return;
      }
      setState(() {
        _callActive = false;
        _callVideoEnabled = false;
        _callMuted = false;
        _callSubtitlesEnabled = false;
        _callFlashEnabled = false;
        _callUsingFrontCamera = true;
        _callConnecting = false;
        _callConnected = false;
        _callUpstreamReady = false;
        _callRecording = false;
        _callResponseActive = false;
        _callDebugOverlayExpanded = true;
        _callStatusMessage = '';
        _callLastRealtimeEvent = '';
        _callLastRealtimeError = '';
        _callAssistantText = '';
        _cameraInitializing = false;
        _cameraErrorMessage = null;
      });
    }
  }

  Future<void> _toggleCallVideo() async {
    if (_callVideoEnabled) {
      await _disposeCallCamera();
      if (!mounted) {
        return;
      }
      setState(() {
        _callVideoEnabled = false;
        _callFlashEnabled = false;
        _cameraErrorMessage = null;
      });
      await _stopCallImageStream();
      return;
    }
    setState(() {
      _callVideoEnabled = true;
      _cameraErrorMessage = null;
    });
    await _ensureCallCameraReady();
    await _startCallImageStream();
  }

  Future<void> _toggleCallFlash() async {
    final controller = _cameraController;
    if (!_callVideoEnabled ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    try {
      final nextState = !_callFlashEnabled;
      await controller.setFlashMode(
        nextState ? FlashMode.torch : FlashMode.off,
      );
      if (!mounted) {
        return;
      }
      setState(() => _callFlashEnabled = nextState);
    } on CameraException catch (error) {
      if (mounted) {
        context.showCenteredNotice(_describeCameraException(error));
        setState(() => _callFlashEnabled = false);
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
        setState(() => _callFlashEnabled = false);
      }
    }
  }

  void _toggleCallMute() {
    setState(() {
      _callMuted = !_callMuted;
      _callStatusMessage = _callMuted
          ? _t(context, '麦克风已静音', 'Microphone muted')
          : _t(context, '你可以开始说话', 'You can start talking');
    });
  }

  Future<void> _startRealtimeCall() async {
    if (_callConnecting || _callConnected) {
      return;
    }
    setState(() {
      _callConnecting = true;
      _callStatusMessage = _t(
        context,
        '正在连接实时 AI',
        'Connecting to realtime AI',
      );
      _callAssistantText = '';
      _callLastRealtimeEvent = 'client.connect';
      _callLastRealtimeError = '';
      _callSavedUserTranscriptIds.clear();
      _callOutputPcmChunks.clear();
      _callAudioPlaybackQueue.clear();
      _callSentAudioChunks = 0;
      _callSentVideoFrames = 0;
      _callPlayedAudioSegments = 0;
      _callAudioReadyForFrame = false;
      _callPendingAudioTurn = false;
      _callPendingAudioTurnStartedAt = null;
      _callResponseActive = false;
      _callLastVideoFrameAt = null;
    });

    try {
      await _configureCallAudioSession();
      final repository = ref.read(chatRepositoryProvider);
      final config = await repository.fetchRealtimeConfig();
      final token = await repository.readAccessToken();
      if (token.isEmpty) {
        throw StateError(_t(context, '登录状态已失效，请重新登录', 'Please sign in again'));
      }

      final uri = _buildRealtimeUri(config, token);
      final socket = await WebSocket.connect(uri.toString());
      _callSocket = socket;
      _callStartedAt = DateTime.now();
      setState(() {
        _callConnecting = false;
        _callConnected = true;
        _callStatusMessage = _t(context, '正在等待 AI 就绪', 'Waiting for AI');
      });

      socket.listen(
        _handleRealtimeMessage,
        onError: (Object error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _callStatusMessage = error.toString();
            _callLastRealtimeError = error.toString();
            _callConnected = false;
            _callUpstreamReady = false;
          });
        },
        onDone: () {
          if (!mounted) {
            return;
          }
          _stopCallTurnTimers();
          _stopCallResponseTimeoutTimer();
          setState(() {
            _callConnected = false;
            _callUpstreamReady = false;
            _callRecording = false;
            _callResponseActive = false;
            _callLastRealtimeEvent = 'socket.done';
            if (_callActive) {
              _callStatusMessage = _t(
                context,
                '实时连接已断开',
                'Realtime connection closed',
              );
            }
          });
          unawaited(_stopCallImageStream());
          unawaited(_stopCallAudio());
        },
        cancelOnError: true,
      );
      _startCallPingTimer();
    } on Object catch (error) {
      await _stopRealtimeCall();
      if (!mounted) {
        return;
      }
      setState(() {
        _callConnecting = false;
        _callStatusMessage = error.toString();
        _callLastRealtimeError = error.toString();
      });
      context.showCenteredNotice(error.toString());
    }
  }

  Uri _buildRealtimeUri(ChatRealtimeConfig config, String token) {
    final baseUri = Uri.parse(config.wsUrl);
    final query = Map<String, String>.from(baseUri.queryParameters);
    query['token'] = token;
    if (config.configId > 0) {
      query['config_id'] = config.configId.toString();
    }
    if (config.defaultModel.trim().isNotEmpty) {
      query['model'] = config.defaultModel.trim();
    }

    return baseUri.replace(queryParameters: query);
  }

  Future<void> _configureCallAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker |
            AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.allowBluetoothA2dp,
        avAudioSessionMode: AVAudioSessionMode.videoChat,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );
    await session.setActive(true);
    await _callAudioPlayer.setVolume(1);
  }

  Future<void> _stopRealtimeCall() async {
    _stopCallDebugTicker();
    _stopCallPingTimer();
    await _stopCallImageStream();
    _stopCallAudioWatchdog();
    _stopCallTurnTimers();
    _stopCallResponseTimeoutTimer();
    await _stopCallAudio();
    final socket = _callSocket;
    _callSocket = null;
    if (socket != null) {
      await socket.close();
    }
    await _callAudioPlayer.stop();
    _callPlayingRealtimeAudio = false;
    _callOutputPcmChunks.clear();
    _callAudioPlaybackQueue.clear();
    _callSavedUserTranscriptIds.clear();
    _callAudioReadyForFrame = false;
    _callPendingAudioTurn = false;
    _callResponseActive = false;
    _callLastVideoFrameAt = null;
    _callPendingAudioTurnStartedAt = null;
    if (mounted) {
      setState(() {
        _callConnecting = false;
        _callConnected = false;
        _callUpstreamReady = false;
        _callRecording = false;
        _callResponseActive = false;
        _callLastRealtimeEvent = 'client.stop';
      });
    } else {
      _callConnecting = false;
      _callConnected = false;
      _callUpstreamReady = false;
      _callRecording = false;
      _callLastRealtimeEvent = 'client.stop';
    }
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } on Object {
      // Ignore audio-session teardown failures while closing the call.
    }
  }

  void _startCallDebugTicker() {
    _stopCallDebugTicker();
    _callDebugTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_callActive) {
        return;
      }
      setState(() {});
    });
  }

  void _stopCallDebugTicker() {
    _callDebugTicker?.cancel();
    _callDebugTicker = null;
  }

  void _startCallResponseTimeoutTimer() {
    _stopCallResponseTimeoutTimer();
    _callResponseTimeoutTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted || !_callActive || !_callResponseActive) {
        return;
      }
      setState(() {
        _callResponseActive = false;
        _callLastRealtimeError = 'response timeout';
        _callStatusMessage = _t(
          context,
          'AI 响应超时，请再说一次',
          'AI response timed out. Please try again.',
        );
      });
    });
  }

  void _stopCallResponseTimeoutTimer() {
    _callResponseTimeoutTimer?.cancel();
    _callResponseTimeoutTimer = null;
  }

  List<String> _callDebugLines() {
    final cameraValue = _cameraController?.value;
    final cameraReady = cameraValue?.isInitialized == true;
    final imageStreaming = cameraValue?.isStreamingImages == true;
    final connectedForMs = _callStartedAt == null
        ? 0
        : DateTime.now().difference(_callStartedAt!).inMilliseconds;
    final lastFrameAge = _callLastVideoFrameAt == null
        ? '-'
        : '${DateTime.now().difference(_callLastVideoFrameAt!).inSeconds}s';
    final turnAge = _callPendingAudioTurnStartedAt == null
        ? '-'
        : '${DateTime.now().difference(_callPendingAudioTurnStartedAt!).inMilliseconds}ms';
    return <String>[
      'ws connecting=${_callFlag(_callConnecting)} connected=${_callFlag(_callConnected)} upstream=${_callFlag(_callUpstreamReady)} age=${connectedForMs}ms',
      'mic recording=${_callFlag(_callRecording)} muted=${_callFlag(_callMuted)} chunks=$_callSentAudioChunks pending=${_callFlag(_callPendingAudioTurn)} turnAge=$turnAge response=${_callFlag(_callResponseActive)}',
      'cam enabled=${_callFlag(_callVideoEnabled)} init=${_callFlag(cameraReady)} stream=${_callFlag(imageStreaming)} frames=$_callSentVideoFrames capturing=${_callFlag(_callCapturingFrame)} last=$lastFrameAge',
      'out pcm=${_callOutputPcmChunks.length} queue=${_callAudioPlaybackQueue.length} played=$_callPlayedAudioSegments playing=${_callFlag(_callAudioPlayer.playing || _callPlayingRealtimeAudio)} text=${_callAssistantText.length} userSaved=${_callSavedUserTranscriptIds.length}',
      'event=${_callLastRealtimeEvent.isEmpty ? '-' : _callLastRealtimeEvent}',
      if ((_cameraErrorMessage ?? '').trim().isNotEmpty)
        'camErr=${_cameraErrorMessage!.trim()}',
      if (_callLastRealtimeError.isNotEmpty) 'err=$_callLastRealtimeError',
      if (_callStatusMessage.trim().isNotEmpty)
        'status=${_callStatusMessage.trim()}',
    ];
  }

  String _callFlag(bool value) => value ? '1' : '0';

  void _handleRealtimeMessage(dynamic raw) {
    if (raw is! String) {
      return;
    }
    final Object? payload;
    try {
      payload = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (payload is! Map<String, dynamic>) {
      return;
    }

    final type = (payload['type'] ?? '').toString();
    _callLastRealtimeEvent = type.isEmpty ? 'unknown' : type;
    if (type == 'session.created') {
      setState(() {
        _callUpstreamReady = true;
        _callLastRealtimeError = '';
        _callStatusMessage = _t(
          context,
          'AI 已就绪，你可以开始说话',
          'AI is ready. You can talk now',
        );
      });
      _sendRealtimeJson({
        'type': 'session.update',
        'event_id': _realtimeEventId('session'),
        'session': _buildRealtimeSession(payload['session']),
      });
      unawaited(_startCallAudio());
      unawaited(_startCallImageStream());
      return;
    }

    if (type == 'session.updated') {
      setState(() {
        _callStatusMessage = _t(context, '正在聆听', 'Listening');
      });
      return;
    }

    if (type == 'response.started') {
      _startCallResponseTimeoutTimer();
      setState(() {
        _callStatusMessage = _t(context, 'AI 正在回答', 'AI is responding');
        _callAssistantText = '';
        _callLastRealtimeError = '';
      });
      _callResponseActive = true;
      _callOutputPcmChunks.clear();
      _callAudioPlaybackQueue.clear();
      return;
    }

    if (type == 'conversation.item.input_audio_transcription.delta') {
      final text = (payload['text'] ?? '').toString();
      final stash = (payload['stash'] ?? '').toString();
      final preview = (text + stash).trim();
      if (preview.isNotEmpty) {
        setState(() {
          _callStatusMessage = preview;
        });
      }
      return;
    }

    if (type == 'conversation.item.input_audio_transcription.completed') {
      final itemId = (payload['item_id'] ?? '').toString();
      final transcript = (payload['transcript'] ?? '').toString().trim();
      if (transcript.isNotEmpty) {
        unawaited(_saveRealtimeUserText(transcript, itemId: itemId));
      }
      return;
    }

    if (type == 'conversation.item.input_audio_transcription.failed') {
      setState(() {
        _callLastRealtimeError = 'input_audio_transcription.failed';
        _callStatusMessage = _t(
          context,
          '语音转文字失败，请再说一次',
          'Speech transcription failed. Please try again.',
        );
      });
      return;
    }

    if (type == 'response.text.delta') {
      final delta = (payload['delta'] ?? '').toString();
      if (delta.isNotEmpty) {
        setState(() => _callAssistantText += delta);
      }
      return;
    }

    if (type == 'response.audio.delta') {
      final delta = (payload['delta'] ?? '').toString();
      if (delta.isNotEmpty) {
        _callOutputPcmChunks.add(base64Decode(delta));
        _queueRealtimeAudioPlayback();
      }
      return;
    }

    if (type == 'response.done') {
      _stopCallResponseTimeoutTimer();
      final hasOutputAudio =
          _callOutputPcmChunks.isNotEmpty ||
          _callAudioPlaybackQueue.isNotEmpty ||
          _callPlayingRealtimeAudio;
      final finalTranscript = (payload['transcript'] ?? '').toString().trim();
      if (_callAssistantText.trim().isEmpty && finalTranscript.isNotEmpty) {
        _callAssistantText = finalTranscript;
      }
      _callAudioReadyForFrame = false;
      _callPendingAudioTurn = false;
      _callPendingAudioTurnStartedAt = null;
      _callResponseActive = false;
      _callLastVideoFrameAt = null;
      setState(() {
        _callResponseActive = false;
        _callStatusMessage = _t(context, '你可以继续说话', 'You can continue talking');
      });
      _queueRealtimeAudioPlayback(flush: true);
      unawaited(_saveRealtimeAssistantText(hasOutputAudio: hasOutputAudio));
      return;
    }

    if (type == 'error') {
      _stopCallResponseTimeoutTimer();
      final error = payload['error'];
      final message = error is Map
          ? (error['message'] ?? '').toString()
          : _t(context, '实时会话发生错误', 'Realtime session error');
      final code = error is Map ? (error['code'] ?? '').toString() : '';
      if (message.contains('append image before append audio') ||
          code.contains('image')) {
        unawaited(_stopCallImageStream());
        _callAudioReadyForFrame = false;
      }
      setState(() {
        _callLastRealtimeError = message;
        _callStatusMessage = message;
        _callResponseActive = false;
        if (error is Map && error['fatal'] == true) {
          _callUpstreamReady = false;
        }
      });
      return;
    }
  }

  Map<String, dynamic> _buildRealtimeSession(Object? serverSession) {
    final session = serverSession is Map<String, dynamic>
        ? Map<String, dynamic>.from(serverSession)
        : <String, dynamic>{};
    return <String, dynamic>{
      ...session,
      'modalities': const ['text', 'audio'],
      'input_audio_format': 'pcm16',
      'output_audio_format': 'pcm16',
      'instructions':
          '${_modeDescription(context, widget.chatMode)}\n'
          '请以 HelpSupport 的 AI 心理医生身份进行实时对话，回答要简洁、温和、可执行。'
          '如果用户表达自伤、自杀、伤人或失控风险，立即建议联系家属、当地急救电话或线下精神心理专科。',
      'turn_detection': {'type': 'manual'},
      'temperature': 0.8,
      'tools': const <Object>[],
    };
  }

  Future<void> _startCallAudio() async {
    if (_callRecording || !_callConnected || !_callUpstreamReady) {
      return;
    }
    final hasPermission = await _callRecorder.hasPermission(request: true);
    if (!hasPermission) {
      throw StateError(
        _t(context, '麦克风权限未开启', 'Microphone permission is required'),
      );
    }

    final stream = await _callRecorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
        autoGain: true,
        streamBufferSize: 4096,
      ),
    );
    _callAudioSubscription = stream.listen(
      (chunk) {
        if (_callMuted ||
            !_callConnected ||
            !_callUpstreamReady ||
            _callResponseActive ||
            chunk.isEmpty) {
          return;
        }
        _stopCallAudioWatchdog();
        _sendRealtimeJson({
          'type': 'input_audio_buffer.append',
          'event_id': _realtimeEventId('audio'),
          'audio': base64Encode(chunk),
        });
        _callLastRealtimeEvent = 'client.audio.append';
        _callSentAudioChunks++;
        _callAudioReadyForFrame = true;
        _markCallAudioTurnPending();
        _scheduleCallSilenceCommit();
      },
      onError: (Object error) {
        _stopCallAudioWatchdog();
        if (mounted) {
          setState(() {
            _callStatusMessage = error.toString();
            _callLastRealtimeError = error.toString();
          });
        }
      },
    );
    if (mounted) {
      setState(() {
        _callRecording = true;
        _callStatusMessage = _t(context, '你可以开始说话', 'You can start talking');
      });
      _startCallAudioWatchdog();
    } else {
      _callRecording = true;
    }
  }

  Future<void> _stopCallAudio() async {
    _stopCallAudioWatchdog();
    await _callAudioSubscription?.cancel();
    _callAudioSubscription = null;
    try {
      if (await _callRecorder.isRecording()) {
        await _callRecorder.stop();
      }
    } on Object {
      // Ignore teardown failures while closing the realtime call.
    }
    _callRecording = false;
  }

  void _startCallAudioWatchdog() {
    _stopCallAudioWatchdog();
    _callAudioWatchdogTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted ||
          !_callActive ||
          !_callConnected ||
          !_callUpstreamReady ||
          !_callRecording ||
          _callSentAudioChunks > 0) {
        return;
      }
      setState(() {
        _callStatusMessage = _t(
          context,
          '未收到麦克风音频，请检查 BlueStacks 麦克风或改用真机测试',
          'No microphone audio was received. Check BlueStacks microphone or test on a real device.',
        );
      });
    });
  }

  void _stopCallAudioWatchdog() {
    _callAudioWatchdogTimer?.cancel();
    _callAudioWatchdogTimer = null;
  }

  void _markCallAudioTurnPending() {
    if (_callPendingAudioTurn) {
      return;
    }
    _callPendingAudioTurn = true;
    _callPendingAudioTurnStartedAt = DateTime.now();
    _scheduleCallMaxCommit();
  }

  void _scheduleCallSilenceCommit() {
    _stopCallSilenceCommitTimer();
    _callTurnCommitTimer = Timer(const Duration(milliseconds: 1200), () {
      _commitCallAudioTurn();
    });
  }

  void _scheduleCallMaxCommit() {
    _stopCallMaxCommitTimer();
    _callTurnMaxCommitTimer = Timer(const Duration(seconds: 3), () {
      _commitCallAudioTurn();
    });
  }

  void _stopCallTurnTimers() {
    _stopCallSilenceCommitTimer();
    _stopCallMaxCommitTimer();
  }

  void _stopCallSilenceCommitTimer() {
    _callTurnCommitTimer?.cancel();
    _callTurnCommitTimer = null;
  }

  void _stopCallMaxCommitTimer() {
    _callTurnMaxCommitTimer?.cancel();
    _callTurnMaxCommitTimer = null;
  }

  void _commitCallAudioTurn() {
    _stopCallTurnTimers();
    if (!_callPendingAudioTurn ||
        !_callConnected ||
        !_callUpstreamReady ||
        _callResponseActive) {
      return;
    }
    _callPendingAudioTurn = false;
    _callPendingAudioTurnStartedAt = null;
    _callResponseActive = true;
    _callLastRealtimeEvent = 'client.response.create';
    _startCallResponseTimeoutTimer();
    _sendRealtimeJson({
      'type': 'input_audio_buffer.commit',
      'event_id': _realtimeEventId('commit'),
    });
    _sendRealtimeJson({
      'type': 'response.create',
      'event_id': _realtimeEventId('response'),
    });
    if (mounted) {
      setState(() {
        _callStatusMessage = _t(context, 'AI 正在思考', 'AI is thinking');
      });
    }
  }

  Future<void> _saveRealtimeAssistantText({
    required bool hasOutputAudio,
  }) async {
    final content = _callAssistantText.trim();
    if (content.isEmpty) {
      if (mounted && !hasOutputAudio) {
        setState(() {
          _callStatusMessage = _t(
            context,
            'AI 未返回文本或音频，请再说一次',
            'AI returned no text or audio. Please try again.',
          );
        });
      }
      return;
    }
    try {
      await ref
          .read(chatRepositoryProvider)
          .saveRealtimeAssistantRecord(
            sessionId: widget.sessionId,
            content: content,
          );
      ref.invalidate(chatRecordsProvider(widget.sessionId));
      ref.invalidate(chatOverviewProvider);
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    }
  }

  Future<void> _saveRealtimeUserText(
    String content, {
    required String itemId,
  }) async {
    final key = itemId.trim().isEmpty ? content : itemId.trim();
    if (_callSavedUserTranscriptIds.contains(key)) {
      return;
    }
    _callSavedUserTranscriptIds.add(key);
    try {
      await ref
          .read(chatRepositoryProvider)
          .saveUserRecord(sessionId: widget.sessionId, content: content);
      ref.invalidate(chatRecordsProvider(widget.sessionId));
      ref.invalidate(chatOverviewProvider);
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    }
  }

  Future<void> _startCallImageStream() async {
    final controller = _cameraController;
    if (!_callVideoEnabled ||
        !_callConnected ||
        !_callUpstreamReady ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }
    try {
      await controller.startImageStream(_handleCallCameraImage);
      _callLastRealtimeEvent = 'client.image.stream.start';
    } on CameraException catch (error) {
      if (mounted) {
        setState(() {
          _cameraErrorMessage = _describeCameraException(error);
          _callLastRealtimeError = _cameraErrorMessage ?? error.toString();
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _cameraErrorMessage = error.toString();
          _callLastRealtimeError = error.toString();
        });
      }
    }
  }

  Future<void> _stopCallImageStream() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        !controller.value.isStreamingImages) {
      return;
    }
    try {
      await controller.stopImageStream();
      _callLastRealtimeEvent = 'client.image.stream.stop';
    } on CameraException {
      // Ignore teardown failures while closing or switching the call camera.
    }
  }

  void _handleCallCameraImage(CameraImage frame) {
    if (_callCapturingFrame ||
        !_callVideoEnabled ||
        !_callConnected ||
        !_callUpstreamReady ||
        _callSentAudioChunks <= 0) {
      return;
    }
    final lastFrameAt = _callLastVideoFrameAt;
    if (lastFrameAt != null &&
        DateTime.now().difference(lastFrameAt) < const Duration(seconds: 2)) {
      return;
    }
    _callCapturingFrame = true;
    _callLastVideoFrameAt = DateTime.now();
    unawaited(_sendCallVideoFrame(frame));
  }

  Future<void> _sendCallVideoFrame(CameraImage frame) async {
    try {
      final bytes = _encodeCameraImageAsJpeg(frame);
      if (bytes == null || bytes.isEmpty) {
        return;
      }
      _sendRealtimeJson({
        'type': 'input_image.append',
        'event_id': _realtimeEventId('frame'),
        'image': base64Encode(bytes),
        'mime_type': 'image/jpeg',
        'timestamp_ms': _callStartedAt == null
            ? 0
            : DateTime.now().difference(_callStartedAt!).inMilliseconds,
      });
      _callLastRealtimeEvent = 'client.image.append';
      _callSentVideoFrames++;
    } on Object {
      // Frame upload is best-effort; keep the call alive.
    } finally {
      _callCapturingFrame = false;
    }
  }

  Uint8List? _encodeCameraImageAsJpeg(CameraImage frame) {
    final image = switch (frame.format.group) {
      ImageFormatGroup.yuv420 => _convertYuv420ToImage(frame),
      ImageFormatGroup.bgra8888 => _convertBgra8888ToImage(frame),
      _ => null,
    };
    if (image == null) {
      return null;
    }
    final resized = image.width > 480
        ? image_lib.copyResize(image, width: 480)
        : image;
    return Uint8List.fromList(image_lib.encodeJpg(resized, quality: 70));
  }

  image_lib.Image? _convertYuv420ToImage(CameraImage frame) {
    if (frame.planes.length < 3) {
      return null;
    }
    final width = frame.width;
    final height = frame.height;
    final yPlane = frame.planes[0];
    final uPlane = frame.planes[1];
    final vPlane = frame.planes[2];
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;
    final image = image_lib.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      final yRow = yPlane.bytesPerRow * y;
      final uRow = uPlane.bytesPerRow * (y >> 1);
      final vRow = vPlane.bytesPerRow * (y >> 1);
      for (var x = 0; x < width; x++) {
        final yValue = yPlane.bytes[yRow + x];
        final uIndex = uRow + (x >> 1) * uPixelStride;
        final vIndex = vRow + (x >> 1) * vPixelStride;
        final uValue = uPlane.bytes[uIndex];
        final vValue = vPlane.bytes[vIndex];
        final r = (yValue + 1.402 * (vValue - 128)).round();
        final g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .round();
        final b = (yValue + 1.772 * (uValue - 128)).round();
        image.setPixelRgb(x, y, _clampColor(r), _clampColor(g), _clampColor(b));
      }
    }
    return image;
  }

  image_lib.Image? _convertBgra8888ToImage(CameraImage frame) {
    if (frame.planes.isEmpty) {
      return null;
    }
    final width = frame.width;
    final height = frame.height;
    final plane = frame.planes.first;
    final image = image_lib.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      final rowOffset = y * plane.bytesPerRow;
      for (var x = 0; x < width; x++) {
        final offset = rowOffset + x * 4;
        final b = plane.bytes[offset];
        final g = plane.bytes[offset + 1];
        final r = plane.bytes[offset + 2];
        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
  }

  int _clampColor(int value) => value.clamp(0, 255).toInt();

  void _startCallPingTimer() {
    _stopCallPingTimer();
    _callPingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _sendRealtimeJson({'type': 'ping', 'event_id': _realtimeEventId('ping')});
    });
  }

  void _stopCallPingTimer() {
    _callPingTimer?.cancel();
    _callPingTimer = null;
  }

  void _sendRealtimeJson(Map<String, dynamic> payload) {
    final socket = _callSocket;
    if (socket == null || socket.readyState != WebSocket.open) {
      return;
    }
    socket.add(jsonEncode(payload));
  }

  String _realtimeEventId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(0x7fffffff)}';
  }

  void _queueRealtimeAudioPlayback({bool flush = false}) {
    if (_callOutputPcmChunks.isEmpty) {
      return;
    }
    if (!flush && _callOutputPcmChunks.length < 8) {
      return;
    }
    _callAudioPlaybackQueue.add(List<Uint8List>.from(_callOutputPcmChunks));
    _callOutputPcmChunks.clear();
    unawaited(_drainRealtimeAudioQueue());
  }

  Future<void> _drainRealtimeAudioQueue() async {
    if (_callPlayingRealtimeAudio) {
      return;
    }
    _callPlayingRealtimeAudio = true;
    try {
      while (_callAudioPlaybackQueue.isNotEmpty) {
        final chunks = _callAudioPlaybackQueue.removeFirst();
        await _playRealtimeAudioChunks(chunks);
        _callPlayedAudioSegments++;
        if (mounted && _callActive) {
          setState(() {});
        }
      }
    } on Object catch (error) {
      if (mounted && _callActive) {
        setState(() {
          _callLastRealtimeError = error.toString();
          _callStatusMessage = _t(
            context,
            'AI 声音播放失败',
            'AI audio playback failed',
          );
        });
      }
    } finally {
      _callPlayingRealtimeAudio = false;
      if (mounted && _callActive) {
        setState(() {});
      }
    }
  }

  Future<void> _playRealtimeAudioChunks(List<Uint8List> chunks) async {
    if (chunks.isEmpty) {
      return;
    }
    final wavBytes = _buildPcm16Wav(chunks, sampleRate: 24000);

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/helpsupport-realtime-${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await file.writeAsBytes(wavBytes, flush: true);
    await _callAudioPlayer.setFilePath(file.path);
    await _callAudioPlayer.play();
  }

  Uint8List _buildPcm16Wav(List<Uint8List> chunks, {required int sampleRate}) {
    final pcmLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final bytes = Uint8List(44 + pcmLength);
    final data = ByteData.view(bytes.buffer);
    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes[offset + i] = value.codeUnitAt(i);
      }
    }

    writeAscii(0, 'RIFF');
    data.setUint32(4, 36 + pcmLength, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    data.setUint32(40, pcmLength, Endian.little);

    var offset = 44;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return bytes;
  }

  Future<void> _flipCallCamera() async {
    if (!_callVideoEnabled) {
      return;
    }
    final nextDirection = _callUsingFrontCamera
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    if (_availableCameras.length <= 1 &&
        _pickCamera(_availableCameras, nextDirection) == null) {
      if (mounted) {
        context.showCenteredNotice(
          _t(context, '当前设备没有可切换的镜头', 'No alternate camera is available.'),
        );
      }
      return;
    }
    setState(() {
      _callUsingFrontCamera = !_callUsingFrontCamera;
      _callFlashEnabled = false;
      _cameraErrorMessage = null;
    });
    await _ensureCallCameraReady(
      forceReinitialize: true,
      preferredDirection: nextDirection,
    );
  }

  Future<void> _ensureCallCameraReady({
    bool forceReinitialize = false,
    CameraLensDirection? preferredDirection,
  }) async {
    if (!_callActive || !_callVideoEnabled || _cameraInitializing) {
      return;
    }
    final permissionService = ref.read(permissionServiceProvider);
    if (mounted) {
      setState(() {
        _cameraInitializing = true;
        _cameraErrorMessage = null;
      });
    } else {
      _cameraInitializing = true;
      _cameraErrorMessage = null;
    }

    try {
      final statuses = await permissionService.requestVideoCallPermissions();
      final deniedMessage = _describeVideoPermissionFailure(statuses);
      if (deniedMessage != null) {
        throw _CallCameraSetupException(deniedMessage);
      }
      if (!_callActive || !_callVideoEnabled) {
        return;
      }

      final cameras = forceReinitialize || _availableCameras.isEmpty
          ? await availableCameras()
          : _availableCameras;
      _availableCameras = cameras;
      if (cameras.isEmpty) {
        throw _CallCameraSetupException(
          _t(context, '当前设备没有可用摄像头', 'No camera is available on this device.'),
        );
      }

      final targetDirection =
          preferredDirection ??
          (_callUsingFrontCamera
              ? CameraLensDirection.front
              : CameraLensDirection.back);
      final description =
          _pickCamera(cameras, targetDirection) ?? cameras.first;

      final previousController = _cameraController;
      final nextController = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      _cameraController = nextController;
      if (previousController != null) {
        if (previousController.value.isInitialized &&
            previousController.value.isStreamingImages) {
          try {
            await previousController.stopImageStream();
          } on CameraException {
            // Ignore teardown failures while switching cameras.
          }
        }
        await previousController.dispose();
      }
      await nextController.initialize();

      try {
        await nextController.lockCaptureOrientation();
      } on CameraException {
        // Some devices/simulators don't support orientation lock for this stream.
      }

      try {
        await nextController.setFlashMode(FlashMode.off);
      } on CameraException {
        // Ignore and keep the UI fallback; toggle action will surface failures.
      }

      if (!_callActive || !_callVideoEnabled) {
        await nextController.dispose();
        if (identical(_cameraController, nextController)) {
          _cameraController = null;
        }
        return;
      }
      if (!mounted) {
        await nextController.dispose();
        return;
      }
      setState(() {
        _callUsingFrontCamera =
            description.lensDirection != CameraLensDirection.back;
        _callFlashEnabled = false;
        _cameraErrorMessage = null;
      });
      await _startCallImageStream();
    } on CameraException catch (error) {
      await _disposeCallCamera();
      if (!mounted) {
        return;
      }
      setState(() {
        _callFlashEnabled = false;
        _cameraErrorMessage = _describeCameraException(error);
      });
      context.showCenteredNotice(_cameraErrorMessage!);
    } on _CallCameraSetupException catch (error) {
      await _disposeCallCamera();
      if (!mounted) {
        return;
      }
      setState(() {
        _callFlashEnabled = false;
        _cameraErrorMessage = error.message;
      });
      context.showCenteredNotice(error.message);
    } on Object catch (error) {
      await _disposeCallCamera();
      if (!mounted) {
        return;
      }
      final message = error.toString();
      setState(() {
        _callFlashEnabled = false;
        _cameraErrorMessage = message;
      });
      context.showCenteredNotice(message);
    } finally {
      if (mounted) {
        setState(() => _cameraInitializing = false);
      } else {
        _cameraInitializing = false;
      }
    }
  }

  Future<void> _disposeCallCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      if (controller.value.isInitialized &&
          controller.value.isStreamingImages) {
        try {
          await controller.stopImageStream();
        } on CameraException {
          // Ignore teardown failures while closing the call camera.
        }
      }
      await controller.dispose();
    }
  }

  CameraDescription? _pickCamera(
    List<CameraDescription> cameras,
    CameraLensDirection direction,
  ) {
    for (final camera in cameras) {
      if (camera.lensDirection == direction) {
        return camera;
      }
    }
    return null;
  }

  String? _describeVideoPermissionFailure(
    Map<Permission, PermissionStatus> statuses,
  ) {
    final blocked = <String>[];
    final cameraStatus = statuses[Permission.camera];
    final micStatus = statuses[Permission.microphone];
    if (cameraStatus != null && !cameraStatus.isGranted) {
      blocked.add(_t(context, '相机', 'Camera'));
    }
    if (micStatus != null && !micStatus.isGranted) {
      blocked.add(_t(context, '麦克风', 'Microphone'));
    }
    if (blocked.isEmpty) {
      return null;
    }
    return _t(
      context,
      '${blocked.join('、')}权限未开启，请先授权后再发起视频通话',
      '${blocked.join(', ')} permission is required before starting a video call.',
    );
  }

  String _describeCameraException(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
        return _t(
          context,
          '相机权限被拒绝，请在系统设置中允许 HelpSupport 访问相机',
          'Camera access was denied. Allow HelpSupport to access the camera in Settings.',
        );
      case 'AudioAccessDenied':
        return _t(
          context,
          '麦克风权限被拒绝，请在系统设置中允许 HelpSupport 访问麦克风',
          'Microphone access was denied. Allow HelpSupport to access the microphone in Settings.',
        );
      case 'CameraAccessRestricted':
      case 'AudioAccessRestricted':
        return _t(
          context,
          '系统限制了音视频权限，请检查设备限制设置',
          'System restrictions are preventing audio/video access.',
        );
      default:
        return error.description?.trim().isNotEmpty == true
            ? error.description!.trim()
            : error.code;
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

    final now = _localMessageTime();
    final tempUserId = -DateTime.now().microsecondsSinceEpoch;
    final baseRecordId = _currentMaxRecordId();
    final generation = ++_sendGeneration;
    _streamSyncTimer?.cancel();
    unawaited(_streamSubscription?.cancel() ?? Future<void>.value());
    setState(() {
      _sending = true;
      _streamingRecords = [
        ChatRecord(
          id: tempUserId,
          sessionId: widget.sessionId,
          chatMode: widget.chatMode,
          role: 'user',
          content: content,
          contentType: 'text',
          messageTime: now,
        ),
        ChatRecord(
          id: tempUserId - 1,
          sessionId: widget.sessionId,
          chatMode: widget.chatMode,
          role: 'assistant',
          content: '',
          contentType: 'text',
          messageTime: now,
        ),
      ];
    });
    _scrollToLatest();
    _controller.clear();
    _startStreamRecordSync(generation, baseRecordId);

    _streamSubscription = ref
        .read(chatRepositoryProvider)
        .sendMessageStream(
          sessionId: widget.sessionId,
          chatMode: widget.chatMode,
          content: content,
        )
        .listen(
          (event) {
            if (!mounted || generation != _sendGeneration) {
              return;
            }
            _applyStreamEvent(event);
            if (event.type == 'done' || event.type == 'error') {
              _completeStreamingSend(generation);
            }
          },
          onError: (Object error) {
            unawaited(
              _syncRecordsAfterSend(
                generation: generation,
                baseRecordId: baseRecordId,
                finishWhenAssistantExists: true,
              ).then((synced) {
                if (!mounted || generation != _sendGeneration || synced) {
                  return;
                }
                setState(() => _streamingRecords = const <ChatRecord>[]);
                context.showCenteredNotice(error.toString());
                _completeStreamingSend(generation);
              }),
            );
          },
          onDone: () {
            unawaited(
              _syncRecordsAfterSend(
                    generation: generation,
                    baseRecordId: baseRecordId,
                    finishWhenAssistantExists: false,
                  )
                  .then((synced) {
                    if (!mounted || generation != _sendGeneration || synced) {
                      return;
                    }
                    if (!_hasStreamingAssistantContent()) {
                      context.showCenteredNotice(
                        _t(
                          context,
                          'AI 未返回有效内容，请稍后重试',
                          'AI did not return valid content. Try again later.',
                        ),
                      );
                    }
                  })
                  .whenComplete(() => _completeStreamingSend(generation)),
            );
          },
          cancelOnError: false,
        );
  }

  List<ChatRecord> _visibleRecords(List<ChatRecord> records) {
    if (_streamingRecords.isEmpty) {
      return records;
    }
    final existingIds = records.map((record) => record.id).toSet();
    return [
      ...records,
      ..._streamingRecords.where((record) => !existingIds.contains(record.id)),
    ];
  }

  int _currentMaxRecordId() {
    final page = ref.read(chatRecordsProvider(widget.sessionId)).asData?.value;
    final records = page?.list ?? const <ChatRecord>[];
    var maxId = 0;
    for (final record in records) {
      if (record.id > maxId) {
        maxId = record.id;
      }
    }
    return maxId;
  }

  void _applyStreamEvent(ChatStreamEvent event) {
    switch (event.type) {
      case 'start':
        final userRecord = event.userRecord;
        if (userRecord == null) {
          return;
        }
        setState(() {
          _streamingRecords = [
            userRecord,
            ChatRecord(
              id: -DateTime.now().microsecondsSinceEpoch,
              sessionId: userRecord.sessionId,
              chatMode: userRecord.chatMode,
              role: 'assistant',
              content: '',
              contentType: 'text',
              messageTime: userRecord.messageTime,
            ),
          ];
        });
        _scrollToLatest();
        return;
      case 'delta':
        if (event.content.isEmpty) {
          return;
        }
        setState(() {
          _streamingRecords = _streamingRecords
              .map((record) {
                if (record.role != 'assistant') {
                  return record;
                }
                return record.copyWith(content: record.content + event.content);
              })
              .toList(growable: false);
        });
        _scrollToLatest();
        return;
      case 'done':
        setState(() {
          _streamingRecords = event.records.isNotEmpty
              ? event.records
              : const <ChatRecord>[];
        });
        _scrollToLatest();
        return;
      case 'error':
        setState(() => _streamingRecords = const <ChatRecord>[]);
        context.showCenteredNotice(
          event.message.trim().isEmpty
              ? _t(
                  context,
                  'AI 回复失败，请稍后重试',
                  'AI reply failed. Try again later.',
                )
              : event.message,
        );
        return;
      default:
        return;
    }
  }

  void _startStreamRecordSync(int generation, int baseRecordId) {
    _streamSyncTimer?.cancel();
    _streamSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(
        _syncRecordsAfterSend(
          generation: generation,
          baseRecordId: baseRecordId,
          finishWhenAssistantExists: true,
        ),
      );
    });
  }

  Future<bool> _syncRecordsAfterSend({
    required int generation,
    required int baseRecordId,
    required bool finishWhenAssistantExists,
  }) async {
    if (!mounted || generation != _sendGeneration) {
      return false;
    }

    try {
      final page = await ref
          .read(chatRepositoryProvider)
          .fetchRecords(widget.sessionId);
      if (!mounted || generation != _sendGeneration) {
        return false;
      }

      final newRecords = page.list
          .where((record) => record.id > baseRecordId)
          .toList(growable: false);
      if (newRecords.isEmpty) {
        return false;
      }

      final hasAssistant = newRecords.any(
        (record) => !record.isUser && record.content.trim().isNotEmpty,
      );
      final temporaryAssistantRecords = _streamingRecords
          .where(
            (record) =>
                !record.isUser &&
                (finishWhenAssistantExists || record.content.trim().isNotEmpty),
          )
          .toList(growable: false);
      final nextRecords = hasAssistant || temporaryAssistantRecords.isEmpty
          ? newRecords
          : [...newRecords, ...temporaryAssistantRecords];
      setState(() => _streamingRecords = nextRecords);
      _scrollToLatest();
      if (hasAssistant && finishWhenAssistantExists) {
        _completeStreamingSend(generation);
      }
      return hasAssistant;
    } on Object {
      return false;
    }
  }

  bool _hasStreamingAssistantContent() {
    return _streamingRecords.any(
      (record) => !record.isUser && record.content.trim().isNotEmpty,
    );
  }

  void _completeStreamingSend(int generation) {
    if (!mounted || generation != _sendGeneration) {
      return;
    }
    _streamSyncTimer?.cancel();
    _streamSyncTimer = null;
    unawaited(_streamSubscription?.cancel() ?? Future<void>.value());
    _streamSubscription = null;
    setState(() => _sending = false);
    ref.invalidate(chatRecordsProvider(widget.sessionId));
    ref.invalidate(chatOverviewProvider);
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      if (!position.hasContentDimensions) {
        return;
      }
      _scrollController.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _scheduleOnlinePromptGate(String prompt) {
    if (prompt.isNotEmpty || _promptGateShown) {
      return;
    }
    _promptGateShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final nextPrompt = await showChatPromptConfigSheet(
        context,
        chatMode: widget.chatMode,
        title: _t(context, '设置对话提示词', 'Set chat prompt'),
        initialPrompt: '',
      );
      if (!mounted) {
        return;
      }
      if (nextPrompt == null) {
        Navigator.of(context).maybePop();
        return;
      }
      await _saveOnlinePrompt(nextPrompt);
    });
  }

  Future<void> _editOnlinePrompt(String currentPrompt) async {
    final nextPrompt = await showChatPromptConfigSheet(
      context,
      chatMode: widget.chatMode,
      title: _t(context, '修改对话提示词', 'Edit chat prompt'),
      initialPrompt: currentPrompt,
    );
    if (!mounted || nextPrompt == null) {
      return;
    }
    await _saveOnlinePrompt(nextPrompt);
  }

  Future<void> _saveOnlinePrompt(String prompt) async {
    try {
      await ref
          .read(chatRepositoryProvider)
          .saveConfig(chatMode: widget.chatMode, promptText: prompt);
      ref.invalidate(chatConfigProvider(widget.chatMode));
      ref.invalidate(chatOverviewProvider);
      if (mounted) {
        context.showCenteredNotice(_t(context, '提示词已保存', 'Prompt saved'));
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
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
    required this.controller,
    required this.chatMode,
    required this.userAvatarUrl,
    required this.assistantAvatarUrl,
    required this.expandedVoiceTextIds,
    required this.onToggleTranscript,
    required this.onRecordActions,
  });

  final List<ChatRecord> records;
  final ScrollController controller;
  final String chatMode;
  final String userAvatarUrl;
  final String assistantAvatarUrl;
  final Set<int> expandedVoiceTextIds;
  final ValueChanged<ChatRecord> onToggleTranscript;
  final ValueChanged<ChatRecord> onRecordActions;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(child: Text(context.l10n.noMessages));
    }

    return ListView.builder(
      controller: controller,
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
            assistantAvatarUrl: assistantAvatarUrl,
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
    required this.assistantAvatarUrl,
    required this.transcriptExpanded,
    required this.onToggleTranscript,
    required this.onLongPress,
  });

  final ChatRecord record;
  final String chatMode;
  final String userAvatarUrl;
  final String assistantAvatarUrl;
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
              icon: _modeAvatarIcon(chatMode),
              imageUrl: assistantAvatarUrl,
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
        if (!record.isUser) {
          return _MarkdownRecordContent(record: record, textColor: textColor);
        }
        return Text(
          record.content,
          style: TextStyle(color: textColor, fontSize: 16, height: 1.6),
        );
    }
  }
}

class _MarkdownRecordContent extends StatelessWidget {
  const _MarkdownRecordContent({required this.record, required this.textColor});

  final ChatRecord record;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final content = record.content.trim();
    if (content.isEmpty) {
      return Text(
        _t(context, '正在输入...', 'Typing...'),
        style: TextStyle(color: textColor, fontSize: 16, height: 1.6),
      );
    }

    final theme = Theme.of(context);
    final palette = _ChatSessionPalette.of(context);
    final baseTextStyle = theme.textTheme.bodyMedium?.copyWith(
      color: textColor,
      fontSize: 16,
      height: 1.6,
    );
    return MarkdownBody(
      data: record.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: baseTextStyle,
        strong: baseTextStyle?.copyWith(fontWeight: FontWeight.w800),
        em: baseTextStyle?.copyWith(fontStyle: FontStyle.italic),
        listBullet: baseTextStyle,
        blockquote: baseTextStyle?.copyWith(color: palette.secondaryText),
        code: TextStyle(
          color: textColor,
          fontSize: 14,
          height: 1.5,
          backgroundColor: palette.softSurface,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: palette.softSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        a: baseTextStyle?.copyWith(
          color: const Color(0xFF5A81DA),
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
      ),
      onTapLink: (_, href, __) => _openMarkdownLink(href),
    );
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
      return ClipOval(
        child: SizedBox(
          width: 44,
          height: 44,
          child: CachedRemoteImage(
            imageUrl,
            fit: BoxFit.cover,
            placeholder: ColoredBox(color: backgroundColor),
            errorWidget: ColoredBox(
              color: backgroundColor,
              child: Icon(icon, color: palette.avatarIcon),
            ),
          ),
        ),
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
    required this.videoEnabled,
    required this.cameraController,
    required this.cameraInitializing,
    required this.cameraErrorMessage,
    required this.muted,
    required this.subtitlesEnabled,
    required this.connecting,
    required this.connected,
    required this.upstreamReady,
    required this.recording,
    required this.statusMessage,
    required this.assistantText,
    required this.debugLines,
    required this.debugExpanded,
    required this.flashEnabled,
    required this.usingFrontCamera,
    required this.onBackToMessages,
    required this.onEndCall,
    required this.onToggleVideo,
    required this.onToggleMute,
    required this.onToggleSubtitles,
    required this.onToggleDebug,
    required this.onToggleFlash,
    required this.onFlipCamera,
  });

  final bool videoEnabled;
  final CameraController? cameraController;
  final bool cameraInitializing;
  final String? cameraErrorMessage;
  final bool muted;
  final bool subtitlesEnabled;
  final bool connecting;
  final bool connected;
  final bool upstreamReady;
  final bool recording;
  final String statusMessage;
  final String assistantText;
  final List<String> debugLines;
  final bool debugExpanded;
  final bool flashEnabled;
  final bool usingFrontCamera;
  final VoidCallback onBackToMessages;
  final VoidCallback onEndCall;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSubtitles;
  final VoidCallback onToggleDebug;
  final VoidCallback onToggleFlash;
  final VoidCallback onFlipCamera;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final foreground = videoEnabled
        ? Colors.white
        : (isDark ? const Color(0xFFF8EEEB) : const Color(0xFF2F3136));
    final secondaryForeground = videoEnabled
        ? Colors.white.withValues(alpha: 0.72)
        : (isDark ? const Color(0xFFD7C7C3) : const Color(0xFF7D828A));
    final neutralButtonBackground = videoEnabled
        ? const Color(0xFF787878)
        : Colors.white.withValues(alpha: isDark ? 0.14 : 0.34);
    final fallbackPrompt = muted
        ? _t(context, '麦克风已静音', 'Microphone muted')
        : connecting
        ? _t(context, '正在连接实时 AI', 'Connecting to realtime AI')
        : !connected
        ? _t(context, '实时连接未建立', 'Realtime connection is not connected')
        : !upstreamReady
        ? _t(context, '正在等待 AI 就绪', 'Waiting for AI')
        : recording
        ? _t(context, '你可以开始说话', 'You can start talking')
        : _t(context, '正在启动麦克风', 'Starting microphone');
    final prompt = statusMessage.trim().isEmpty
        ? fallbackPrompt
        : statusMessage.trim();
    final subtitle = assistantText.trim().isEmpty
        ? prompt
        : assistantText.trim();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      decoration: BoxDecoration(
        color: videoEnabled ? Colors.black : null,
        gradient: videoEnabled
            ? null
            : LinearGradient(
                colors: isDark
                    ? const [Color(0xFF392C33), Color(0xFF1E2433)]
                    : const [Color(0xFFF7CCD8), Color(0xFFE2E8FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (!videoEnabled)
              const Positioned.fill(
                child: IgnorePointer(child: _CallSoftBackdrop()),
              ),
            Positioned(
              top: 6,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  _CallTopIconButton(
                    icon: Icons.more_horiz_rounded,
                    foregroundColor: foreground,
                    onTap: onBackToMessages,
                  ),
                  const Spacer(),
                  _CallTopIconButton(
                    icon: flashEnabled
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    foregroundColor: foreground,
                    selected: flashEnabled,
                    onTap: videoEnabled ? onToggleFlash : null,
                  ),
                  const SizedBox(width: 8),
                  _CallTopIconButton(
                    icon: Icons.cameraswitch_rounded,
                    foregroundColor: foreground,
                    selected: videoEnabled && !usingFrontCamera,
                    onTap: videoEnabled ? onFlipCamera : null,
                  ),
                  const SizedBox(width: 8),
                  _CallTopIconButton(
                    icon: Icons.subtitles_rounded,
                    foregroundColor: foreground,
                    selected: subtitlesEnabled,
                    onTap: onToggleSubtitles,
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 92, 24, 194),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: videoEnabled
                      ? _CallCameraStage(
                          key: const ValueKey('camera-stage'),
                          cameraController: cameraController,
                          cameraInitializing: cameraInitializing,
                          cameraErrorMessage: cameraErrorMessage,
                          usingFrontCamera: usingFrontCamera,
                          flashEnabled: flashEnabled,
                        )
                      : const _CallMascotStage(key: ValueKey('mascot-stage')),
                ),
              ),
            ),
            if (subtitlesEnabled)
              Positioned(
                top: 62,
                left: 24,
                right: 24,
                child: Center(
                  child: _CallGlassChip(
                    label: subtitle,
                    icon: Icons.subtitles_rounded,
                    darkBackdrop: videoEnabled,
                    maxLines: 2,
                  ),
                ),
              ),
            Positioned(
              top: subtitlesEnabled ? 148 : 64,
              left: 12,
              right: 12,
              child: _CallDebugOverlay(
                lines: debugLines,
                expanded: debugExpanded,
                onToggle: onToggleDebug,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 146,
              child: Column(
                children: [
                  _CallPromptDots(color: foreground),
                  const SizedBox(height: 18),
                  Text(
                    prompt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 42,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallCircleButton(
                    size: 88,
                    color: muted
                        ? const Color(0xFF5A81DA)
                        : neutralButtonBackground,
                    iconColor: muted ? Colors.white : foreground,
                    icon: muted
                        ? Icons.mic_off_rounded
                        : Icons.mic_none_rounded,
                    onTap: onToggleMute,
                  ),
                  _CallCircleButton(
                    size: 92,
                    color: videoEnabled
                        ? Colors.white
                        : Colors.white.withValues(alpha: isDark ? 0.18 : 0.42),
                    iconColor: videoEnabled ? Colors.black : foreground,
                    icon: videoEnabled
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    onTap: onToggleVideo,
                  ),
                  _CallCircleButton(
                    size: 88,
                    color: const Color(0xFFFF4A54),
                    iconColor: Colors.white,
                    icon: Icons.call_end_rounded,
                    onTap: onEndCall,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Text(
                _t(context, '内容由 AI 生成', 'Content generated by AI'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryForeground,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallDebugOverlay extends StatelessWidget {
  const _CallDebugOverlay({
    required this.lines,
    required this.expanded,
    required this.onToggle,
  });

  final List<String> lines;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final visibleLines = expanded
        ? lines
        : lines.isEmpty
        ? const <String>['-']
        : lines.take(1).toList();
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bug_report_rounded,
                            color: Color(0xFFFFB4A8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Debug',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          height: 1.25,
                          fontFamily: 'monospace',
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final line in visibleLines)
                              Text(
                                line,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CallTopIconButton extends StatelessWidget {
  const _CallTopIconButton({
    required this.icon,
    required this.foregroundColor,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? foregroundColor.withValues(alpha: 0.26)
        : (selected ? const Color(0xFFFFB4A8) : foregroundColor);
    return IconButton(
      onPressed: onTap,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
      splashRadius: 22,
      icon: Icon(icon, color: color, size: 30),
    );
  }
}

class _CallCameraStage extends StatelessWidget {
  const _CallCameraStage({
    super.key,
    required this.cameraController,
    required this.cameraInitializing,
    required this.cameraErrorMessage,
    required this.usingFrontCamera,
    required this.flashEnabled,
  });

  final CameraController? cameraController;
  final bool cameraInitializing;
  final String? cameraErrorMessage;
  final bool usingFrontCamera;
  final bool flashEnabled;

  @override
  Widget build(BuildContext context) {
    final controller = cameraController;
    final previewReady = controller != null && controller.value.isInitialized;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (previewReady)
          Positioned.fill(child: _CallCameraPreview(controller: controller))
        else if (cameraInitializing)
          const Center(
            child: SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: Colors.white,
              ),
            ),
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                cameraErrorMessage ??
                    _t(context, '正在等待摄像头画面', 'Waiting for the camera preview'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomLeft,
          child: _CallGlassChip(
            label: usingFrontCamera
                ? _t(context, '前置镜头', 'Front camera')
                : _t(context, '后置镜头', 'Rear camera'),
            icon: usingFrontCamera
                ? Icons.face_retouching_natural_rounded
                : Icons.camera_rear_rounded,
            darkBackdrop: true,
          ),
        ),
        if (flashEnabled)
          Align(
            alignment: Alignment.bottomRight,
            child: _CallGlassChip(
              label: _t(context, '闪光灯已开', 'Flash on'),
              icon: Icons.flash_on_rounded,
              darkBackdrop: true,
            ),
          ),
      ],
    );
  }
}

class _CallCameraPreview extends StatelessWidget {
  const _CallCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _CallMascotStage extends StatelessWidget {
  const _CallMascotStage({super.key});

  static const _mascotAsset = 'assets/branding/ai_call_mascot.png';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 290,
        height: 290,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.92),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22FF9585),
              blurRadius: 36,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: ClipOval(
          child: ColoredBox(
            color: const Color(0xFFDCEAFE),
            child: Transform.scale(
              scale: 1.06,
              child: Image.asset(_mascotAsset, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}

class _CallSoftBackdrop extends StatelessWidget {
  const _CallSoftBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -80,
          child: _BackdropGlow(
            size: 280,
            colors: const [Color(0x55FFB8C1), Color(0x00FFB8C1)],
          ),
        ),
        Positioned(
          right: -90,
          bottom: 150,
          child: _BackdropGlow(
            size: 260,
            colors: const [Color(0x554FA5FF), Color(0x004FA5FF)],
          ),
        ),
        Positioned(
          left: 70,
          bottom: 110,
          child: _BackdropGlow(
            size: 180,
            colors: const [Color(0x33FFD49C), Color(0x00FFD49C)],
          ),
        ),
      ],
    );
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _CallGlassChip extends StatelessWidget {
  const _CallGlassChip({
    required this.label,
    required this.icon,
    required this.darkBackdrop,
    this.maxLines = 1,
  });

  final String label;
  final IconData icon;
  final bool darkBackdrop;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final background = darkBackdrop
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.66);
    final borderColor = darkBackdrop
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.82);
    final foreground = darkBackdrop ? Colors.white : const Color(0xFF303236);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallPromptDots extends StatelessWidget {
  const _CallPromptDots({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(3, (index) {
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.92 - (index * 0.12)),
            shape: BoxShape.circle,
          ),
        );
      }),
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
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.34),
      ),
    );
  }
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

String _localMessageTime() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)} '
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
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

AiRobotProfile _robotProfileFor(
  String chatMode,
  String runtimeMode,
  List<AiRobotProfile>? profiles,
) {
  if (profiles != null) {
    for (final profile in profiles) {
      if (profile.chatMode == chatMode) {
        return profile;
      }
    }
  }
  return AiRobotProfile.fallback(chatMode: chatMode, runtimeMode: runtimeMode);
}

String _resolveRobotAvatar(
  BuildContext context,
  AiRobotProfile profile,
  String Function(String value) resolveUrl,
) {
  final raw = profile.avatarFor(
    darkMode: Theme.of(context).brightness == Brightness.dark,
  );
  return raw.trim().isEmpty ? '' : resolveUrl(raw);
}

IconData _modeAvatarIcon(String mode) {
  return switch (mode) {
    'patient' => Icons.healing_rounded,
    'companion' => Icons.volunteer_activism_rounded,
    _ => Icons.smart_toy_rounded,
  };
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

void _openMarkdownLink(String? href) {
  final value = href?.trim() ?? '';
  if (value.isEmpty) {
    return;
  }
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme) {
    return;
  }
  unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
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

class _CallCameraSetupException implements Exception {
  const _CallCameraSetupException(this.message);

  final String message;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
