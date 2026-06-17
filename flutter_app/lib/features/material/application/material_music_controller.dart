import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers/app_providers.dart';
import '../data/material_models.dart';
import '../data/material_music_support.dart';
import '../data/material_repository.dart';
import 'material_controller.dart';

final materialMusicControllerProvider =
    NotifierProvider<MaterialMusicController, MaterialMusicState>(
      MaterialMusicController.new,
    );

final materialMusicAudioPlayerProvider = Provider<AudioPlayer>((ref) {
  return ref.read(materialMusicControllerProvider.notifier).player;
});

final materialOfflineStatusProvider = FutureProvider.autoDispose
    .family<Map<int, bool>, MaterialOfflineStatusQuery>((ref, query) async {
      final apiClient = ref.watch(apiClientProvider);
      final statuses = <int, bool>{};
      for (final item in query.items) {
        statuses[item.id] = await MaterialMusicSupport.hasCachedResource(
          apiClient,
          item,
        );
      }
      return statuses;
    });

class MaterialOfflineStatusQuery {
  MaterialOfflineStatusQuery({required List<MaterialItem> items})
    : items = List<MaterialItem>.unmodifiable(items),
      _signature = items
          .map(
            (item) =>
                '${item.id}:${item.mediaType}:${item.contentUrl}:${item.lyricUrl}',
          )
          .join('|');

  final List<MaterialItem> items;
  final String _signature;

  @override
  bool operator ==(Object other) {
    return other is MaterialOfflineStatusQuery &&
        other._signature == _signature;
  }

  @override
  int get hashCode => _signature.hashCode;
}

class MaterialMusicState {
  const MaterialMusicState({
    this.currentItem,
    this.playlist = const <MaterialItem>[],
    this.lyrics = '',
    this.resourceUrl = '',
    this.cachePath = '',
    this.errorMessage = '',
    this.isPreparing = false,
    this.isCaching = false,
    this.cacheProgress = 0,
  });

  final MaterialItem? currentItem;
  final List<MaterialItem> playlist;
  final String lyrics;
  final String resourceUrl;
  final String cachePath;
  final String errorMessage;
  final bool isPreparing;
  final bool isCaching;
  final double cacheProgress;

  bool get isCached => cachePath.trim().isNotEmpty && !isCaching;

  MaterialMusicState copyWith({
    MaterialItem? currentItem,
    bool clearCurrentItem = false,
    List<MaterialItem>? playlist,
    String? lyrics,
    String? resourceUrl,
    String? cachePath,
    String? errorMessage,
    bool? isPreparing,
    bool? isCaching,
    double? cacheProgress,
  }) {
    return MaterialMusicState(
      currentItem: clearCurrentItem ? null : (currentItem ?? this.currentItem),
      playlist: playlist ?? this.playlist,
      lyrics: lyrics ?? this.lyrics,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      cachePath: cachePath ?? this.cachePath,
      errorMessage: errorMessage ?? this.errorMessage,
      isPreparing: isPreparing ?? this.isPreparing,
      isCaching: isCaching ?? this.isCaching,
      cacheProgress: cacheProgress ?? this.cacheProgress,
    );
  }
}

class MaterialMusicController extends Notifier<MaterialMusicState> {
  @override
  MaterialMusicState build() {
    _apiClient = ref.read(apiClientProvider);
    _repository = ref.read(materialRepositoryProvider);
    _player = AudioPlayer();
    _positionSubscription = _player.positionStream.listen(_handlePosition);
    _playerStateSubscription = _player.playerStateStream.listen(
      _handlePlayerState,
    );
    ref.onDispose(_dispose);
    return const MaterialMusicState();
  }

  late final ApiClient _apiClient;
  late final MaterialRepository _repository;
  late final AudioPlayer _player;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  DateTime _openedAt = DateTime.now();
  DateTime _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(0);
  String _activeSignature = '';
  int _loadToken = 0;
  bool _isDisposed = false;

  AudioPlayer get player => _player;

  Future<void> openTrack(
    MaterialItem item, {
    required String localeCode,
    List<MaterialItem>? playlist,
    bool autoplay = true,
  }) async {
    final nextPlaylist = _normalizePlaylist(playlist, fallback: item);
    final resourceUrl = MaterialMusicSupport.resolveContentUrl(
      _apiClient,
      item,
    );
    final nextSignature =
        '${item.id}:${item.mediaType}:$resourceUrl:${item.lyricUrl.hashCode}:${item.contentText.hashCode}';

    if (_activeSignature == nextSignature) {
      state = state.copyWith(
        currentItem: item,
        playlist: nextPlaylist,
        errorMessage: '',
      );
      if (autoplay && !_player.playing) {
        await _player.play();
      }
      return;
    }

    final token = ++_loadToken;
    await _saveProgress(force: true);
    _activeSignature = nextSignature;
    _openedAt = DateTime.now();

    final localFile = resourceUrl.isEmpty
        ? null
        : await MaterialMusicSupport.cacheFileFor(item, resourceUrl);
    final hasCachedFile = localFile != null && await localFile.exists();

    state = state.copyWith(
      currentItem: item,
      playlist: nextPlaylist,
      lyrics: '',
      resourceUrl: resourceUrl,
      cachePath: hasCachedFile ? localFile.path : '',
      errorMessage: '',
      isPreparing: true,
      isCaching: false,
      cacheProgress: hasCachedFile ? 100 : 0,
    );

    if (resourceUrl.isEmpty) {
      state = state.copyWith(
        isPreparing: false,
        errorMessage: _t(localeCode, '暂无音乐文件地址', 'Missing music file URL'),
      );
      return;
    }

    final uri = Uri.tryParse(resourceUrl);
    if (uri == null || !uri.hasScheme) {
      state = state.copyWith(
        isPreparing: false,
        errorMessage: _t(localeCode, '音乐地址无效', 'Invalid music URL'),
      );
      return;
    }

    try {
      await _player.stop();
      final duration = hasCachedFile
          ? await _player.setFilePath(localFile!.path)
          : await _player.setUrl(resourceUrl);
      final lyrics = await MaterialMusicSupport.loadLyrics(_apiClient, item);
      final restoredPosition = MaterialMusicSupport.positionFromHistoryProgress(
        duration ?? _player.duration,
        item.historyProgress,
      );
      if (restoredPosition > Duration.zero) {
        await _player.seek(restoredPosition);
      }
      if (_isDisposed || token != _loadToken) {
        return;
      }
      state = state.copyWith(
        currentItem: item,
        playlist: nextPlaylist,
        lyrics: lyrics,
        cachePath: hasCachedFile ? localFile!.path : '',
        errorMessage: '',
        isPreparing: false,
        cacheProgress: hasCachedFile ? 100 : state.cacheProgress,
      );
      if (autoplay) {
        await _player.play();
      }
    } on Object {
      if (_isDisposed || token != _loadToken) {
        return;
      }
      state = state.copyWith(
        isPreparing: false,
        errorMessage: _t(localeCode, '音乐加载失败', 'Failed to load music'),
      );
    }
  }

  void syncCurrentItem(MaterialItem item) {
    final current = state.currentItem;
    if (current == null || current.id != item.id) {
      return;
    }
    final nextPlaylist = state.playlist
        .map((entry) => entry.id == item.id ? item : entry)
        .toList(growable: false);
    state = state.copyWith(currentItem: item, playlist: nextPlaylist);
  }

  void syncPlaylist(List<MaterialItem> items) {
    final nextPlaylist = _normalizePlaylist(items, fallback: state.currentItem);
    if (nextPlaylist.isEmpty) {
      return;
    }
    state = state.copyWith(playlist: nextPlaylist);
  }

  Future<void> togglePlayback() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }
    await _player.play();
  }

  Future<void> seek(Duration position) {
    return _player.seek(position);
  }

  Future<void> playNext({required String localeCode}) async {
    final current = state.currentItem;
    if (current == null) {
      return;
    }
    final playlist = state.playlist;
    final index = playlist.indexWhere((item) => item.id == current.id);
    if (index < 0 || index >= playlist.length - 1) {
      return;
    }
    await openTrack(
      playlist[index + 1],
      localeCode: localeCode,
      playlist: playlist,
      autoplay: true,
    );
  }

  Future<void> playPrevious({required String localeCode}) async {
    final current = state.currentItem;
    if (current == null) {
      return;
    }
    final playlist = state.playlist;
    final index = playlist.indexWhere((item) => item.id == current.id);
    if (index <= 0) {
      return;
    }
    await openTrack(
      playlist[index - 1],
      localeCode: localeCode,
      playlist: playlist,
      autoplay: true,
    );
  }

  Future<void> jumpToTrack(
    MaterialItem item, {
    required String localeCode,
  }) async {
    await openTrack(
      item,
      localeCode: localeCode,
      playlist: state.playlist,
      autoplay: true,
    );
  }

  Future<void> cacheCurrentTrack({required String localeCode}) async {
    final current = state.currentItem;
    final resourceUrl = state.resourceUrl.trim();
    if (current == null ||
        resourceUrl.isEmpty ||
        state.isCaching ||
        state.isCached) {
      return;
    }
    final localFile = await MaterialMusicSupport.cacheFileFor(
      current,
      resourceUrl,
    );
    if (await localFile.exists()) {
      state = state.copyWith(cachePath: localFile.path, cacheProgress: 100);
      return;
    }
    state = state.copyWith(isCaching: true, cacheProgress: 0, errorMessage: '');
    final cachedFile = await MaterialMusicSupport.cacheRemoteFile(
      apiClient: _apiClient,
      resourceUrl: resourceUrl,
      localFile: localFile,
      onProgress: (progress) {
        if (_isDisposed) {
          return;
        }
        state = state.copyWith(cacheProgress: progress);
      },
    );
    if (_isDisposed) {
      return;
    }
    if (cachedFile == null) {
      state = state.copyWith(
        isCaching: false,
        cacheProgress: 0,
        errorMessage: _t(localeCode, '下载失败', 'Download failed'),
      );
      return;
    }
    state = state.copyWith(
      isCaching: false,
      cachePath: cachedFile.path,
      cacheProgress: 100,
    );
  }

  Future<void> clearPlayback() async {
    await _saveProgress(force: true);
    _activeSignature = '';
    _loadToken += 1;
    await _player.stop();
    state = const MaterialMusicState();
  }

  void _handlePosition(Duration position) {
    final item = state.currentItem;
    final duration = _player.duration;
    if (item == null || duration == null || duration.inMilliseconds <= 0) {
      return;
    }
    unawaited(_saveProgress(durationSeconds: position.inSeconds));
  }

  void _handlePlayerState(PlayerState playerState) {
    if (playerState.processingState == ProcessingState.completed) {
      unawaited(_saveProgress(force: true));
    }
  }

  Future<void> _saveProgress({
    bool force = false,
    int durationSeconds = 0,
  }) async {
    final item = state.currentItem;
    if (item == null) {
      return;
    }
    final now = DateTime.now();
    if (!force && now.difference(_lastSavedAt).inSeconds < 5) {
      return;
    }
    _lastSavedAt = now;
    final duration = _player.duration;
    final position = _player.position;
    final progress = duration == null || duration.inMilliseconds <= 0
        ? item.historyProgress.clamp(0, 100).toDouble()
        : (position.inMilliseconds / duration.inMilliseconds * 100)
              .clamp(0, 100)
              .toDouble();
    final elapsedSeconds = durationSeconds > 0
        ? durationSeconds
        : position.inSeconds > 0
        ? position.inSeconds
        : now.difference(_openedAt).inSeconds;
    try {
      await _repository.saveHistory(
        materialId: item.id,
        title: item.title,
        route: '/materials/music/player/${item.id}',
        authorName: item.artist,
        progress: progress,
        durationSeconds: elapsedSeconds,
      );
    } on Object {
      // Ignore save failures to avoid interrupting playback.
    }
  }

  List<MaterialItem> _normalizePlaylist(
    List<MaterialItem>? playlist, {
    MaterialItem? fallback,
  }) {
    final source = playlist ?? const <MaterialItem>[];
    final filtered = source
        .where(MaterialMusicSupport.isAudioItem)
        .toList(growable: true);
    final current = fallback;
    if (current != null &&
        MaterialMusicSupport.isAudioItem(current) &&
        filtered.every((entry) => entry.id != current.id)) {
      filtered.insert(0, current);
    }
    return filtered;
  }

  String _t(String localeCode, String zh, String en) {
    return localeCode == 'zh' ? zh : en;
  }

  @override
  void _dispose() {
    _isDisposed = true;
    unawaited(_saveProgress(force: true));
    final positionSubscription = _positionSubscription;
    final playerStateSubscription = _playerStateSubscription;
    if (positionSubscription != null) {
      unawaited(positionSubscription.cancel());
    }
    if (playerStateSubscription != null) {
      unawaited(playerStateSubscription.cancel());
    }
    unawaited(_player.dispose());
  }
}
