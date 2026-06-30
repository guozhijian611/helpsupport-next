import 'dart:math' as math;

import 'package:flutter/material.dart' hide MaterialPage;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/cache/cached_remote_image.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/material_controller.dart';
import '../application/material_music_controller.dart';
import '../data/material_models.dart';
import '../data/material_music_support.dart';

class MaterialMusicRoutePayload {
  const MaterialMusicRoutePayload({
    required this.item,
    this.playlist = const <MaterialItem>[],
  });

  final MaterialItem item;
  final List<MaterialItem> playlist;
}

class MaterialMusicPlayerScreen extends ConsumerStatefulWidget {
  const MaterialMusicPlayerScreen({
    super.key,
    required this.materialId,
    this.initialItem,
    this.initialPlaylist = const <MaterialItem>[],
    this.initialPage = 0,
  });

  final int materialId;
  final MaterialItem? initialItem;
  final List<MaterialItem> initialPlaylist;
  final int initialPage;

  @override
  ConsumerState<MaterialMusicPlayerScreen> createState() =>
      _MaterialMusicPlayerScreenState();
}

class _MaterialMusicPlayerScreenState
    extends ConsumerState<MaterialMusicPlayerScreen> {
  late final PageController _pageController;
  int _bootstrappedMaterialId = -1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.initialPage.clamp(0, 1),
    );
  }

  @override
  void didUpdateWidget(covariant MaterialMusicPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.materialId != widget.materialId) {
      _bootstrappedMaterialId = -1;
    }
    if (oldWidget.initialPage != widget.initialPage &&
        _pageController.hasClients) {
      _pageController.jumpToPage(widget.initialPage.clamp(0, 1));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final localeCode = Localizations.localeOf(context).languageCode;
    final detailQuery = MaterialDetailQuery(
      id: widget.materialId,
      locale: localeTag,
    );
    final detail = ref.watch(materialDetailProvider(detailQuery));
    final controllerState = ref.watch(materialMusicControllerProvider);
    final controller = ref.read(materialMusicControllerProvider.notifier);
    final player = ref.watch(materialMusicAudioPlayerProvider);

    final fallback = controllerState.currentItem?.id == widget.materialId
        ? controllerState.currentItem
        : widget.initialItem;
    final detailItem = detail.maybeWhen(
      data: (item) => item,
      orElse: () => fallback,
    );

    if (detailItem != null && MaterialMusicSupport.isAudioItem(detailItem)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final current = ref.read(materialMusicControllerProvider).currentItem;
        if (current != null && current.id == detailItem.id) {
          controller.syncCurrentItem(detailItem);
        }
      });
    }

    final activeItem = controllerState.currentItem ?? detailItem;

    final playlistQuery = activeItem == null
        ? null
        : MaterialListQuery(
            materialType: activeItem.materialType,
            categoryId: activeItem.categoryId,
            keyword: '',
            locale: localeTag,
            pageSize: 50,
          );
    final playlist = playlistQuery == null
        ? const AsyncLoading<MaterialPage<MaterialItem>>()
        : ref.watch(materialListProvider(playlistQuery));
    final playlistItems = switch (playlist) {
      AsyncData(:final value) => value.list,
      _ => null,
    };
    final existingQueue = controllerState.playlist;
    final hasExistingQueue =
        detailItem != null &&
        existingQueue.length > 1 &&
        existingQueue.any((entry) => entry.id == detailItem.id);
    final queueSeed = widget.initialPlaylist.isNotEmpty
        ? widget.initialPlaylist
        : hasExistingQueue
        ? existingQueue
        : playlistItems;

    if (detailItem != null &&
        MaterialMusicSupport.isAudioItem(detailItem) &&
        _bootstrappedMaterialId != widget.materialId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _bootstrappedMaterialId == widget.materialId) {
          return;
        }
        _bootstrappedMaterialId = widget.materialId;
        if (queueSeed != null) {
          controller.syncPlaylist(queueSeed);
        }
        controller.openTrack(
          detailItem,
          localeCode: localeCode,
          playlist: queueSeed,
          autoplay: controllerState.currentItem?.id != detailItem.id,
        );
      });
    } else if (queueSeed != null &&
        activeItem != null &&
        controllerState.playlist.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        controller.syncPlaylist(queueSeed);
      });
    }

    final palette = _MaterialMusicPalette.of(context);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(activeItem?.title ?? _t(context, '正在播放', 'Now Playing')),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _t(context, '播放列表', 'Playlist'),
            onPressed: controllerState.playlist.isEmpty
                ? null
                : () => _showQueueSheet(context, localeCode),
            icon: const Icon(Icons.queue_music_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: detail.when(
          data: (detailData) => _MusicPlayerLoadedView(
            item: activeItem ?? detailData,
            player: player,
            controllerState: controllerState,
            pageController: _pageController,
            onToggleCollect: () => _toggleCollect(
              context,
              localeTag: localeTag,
              item: activeItem ?? detailData,
            ),
            onDownload: () => _cacheCurrentTrack(context, localeCode),
            onOpenDetail: () => _openDetail(context, activeItem ?? detailData),
            onCyclePlayMode: controller.cyclePlayMode,
            onPlayPrevious: () =>
                _playAdjacentTrack(context, localeCode, step: -1),
            onTogglePlayback: controller.togglePlayback,
            onPlayNext: () => _playAdjacentTrack(context, localeCode, step: 1),
          ),
          error: (error, _) => activeItem == null
              ? Center(child: Text(error.toString()))
              : _MusicPlayerLoadedView(
                  item: activeItem,
                  player: player,
                  controllerState: controllerState,
                  pageController: _pageController,
                  onToggleCollect: () => _toggleCollect(
                    context,
                    localeTag: localeTag,
                    item: activeItem,
                  ),
                  onDownload: () => _cacheCurrentTrack(context, localeCode),
                  onOpenDetail: () => _openDetail(context, activeItem),
                  onCyclePlayMode: controller.cyclePlayMode,
                  onPlayPrevious: () =>
                      _playAdjacentTrack(context, localeCode, step: -1),
                  onTogglePlayback: controller.togglePlayback,
                  onPlayNext: () =>
                      _playAdjacentTrack(context, localeCode, step: 1),
                ),
          loading: () => activeItem == null
              ? const Center(child: CircularProgressIndicator())
              : _MusicPlayerLoadedView(
                  item: activeItem,
                  player: player,
                  controllerState: controllerState,
                  pageController: _pageController,
                  onToggleCollect: () => _toggleCollect(
                    context,
                    localeTag: localeTag,
                    item: activeItem,
                  ),
                  onDownload: () => _cacheCurrentTrack(context, localeCode),
                  onOpenDetail: () => _openDetail(context, activeItem),
                  onCyclePlayMode: controller.cyclePlayMode,
                  onPlayPrevious: () =>
                      _playAdjacentTrack(context, localeCode, step: -1),
                  onTogglePlayback: controller.togglePlayback,
                  onPlayNext: () =>
                      _playAdjacentTrack(context, localeCode, step: 1),
                ),
        ),
      ),
    );
  }

  Future<void> _toggleCollect(
    BuildContext context, {
    required String localeTag,
    required MaterialItem item,
  }) async {
    try {
      final isCollected = await ref
          .read(materialRepositoryProvider)
          .toggleCollect(item.id);
      final nextCount = isCollected
          ? item.isCollected
                ? item.collectCount
                : item.collectCount + 1
          : math.max(0, item.collectCount - (item.isCollected ? 1 : 0));
      final nextItem = item.copyWith(
        isCollected: isCollected,
        collectCount: nextCount,
      );
      ref
          .read(materialMusicControllerProvider.notifier)
          .syncCurrentItem(nextItem);
      ref.invalidate(
        materialDetailProvider(
          MaterialDetailQuery(id: item.id, locale: localeTag),
        ),
      );
      ref.invalidate(
        materialCollectionsProvider(
          MaterialListQuery(
            materialType: '',
            categoryId: 0,
            keyword: '',
            locale: localeTag,
          ),
        ),
      );
      ref.invalidate(
        materialListProvider(
          MaterialListQuery(
            materialType: item.materialType,
            categoryId: item.categoryId,
            keyword: '',
            locale: localeTag,
          ),
        ),
      );
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(
        isCollected
            ? _t(context, '已加入收藏', 'Added to collections')
            : _t(context, '已取消收藏', 'Removed from collections'),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  Future<void> _cacheCurrentTrack(
    BuildContext context,
    String localeCode,
  ) async {
    final controller = ref.read(materialMusicControllerProvider.notifier);
    final before = ref.read(materialMusicControllerProvider);
    if (before.isCached || before.isCaching) {
      return;
    }
    await controller.cacheCurrentTrack(localeCode: localeCode);
    if (!context.mounted) {
      return;
    }
    final after = ref.read(materialMusicControllerProvider);
    if (after.errorMessage.trim().isNotEmpty) {
      context.showCenteredNotice(after.errorMessage);
    }
  }

  void _openDetail(BuildContext context, MaterialItem item) {
    context.push('/materials/detail/${item.id}', extra: item);
  }

  Future<void> _showQueueSheet(BuildContext context, String localeCode) async {
    final state = ref.read(materialMusicControllerProvider);
    final activeId = state.currentItem?.id ?? 0;
    final apiClient = ref.read(apiClientProvider);
    final selectedTrack = await showModalBottomSheet<MaterialItem>(
      context: context,
      backgroundColor: _MaterialMusicPalette.of(context).cardBackground,
      showDragHandle: true,
      builder: (sheetContext) {
        final palette = _MaterialMusicPalette.of(sheetContext);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
          itemCount: state.playlist.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (sheetContext, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _t(sheetContext, '播放列表', 'Playlist'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }
            final track = state.playlist[index - 1];
            final selected = track.id == activeId;
            return Material(
              color: selected
                  ? palette.selectedBackground
                  : palette.softBackground,
              borderRadius: BorderRadius.circular(18),
              child: ListTile(
                onTap: selected
                    ? null
                    : () => Navigator.of(sheetContext).pop(track),
                leading: _QueueTrackArtwork(
                  coverUrl: apiClient.resolveUrl(track.coverUrl),
                  selected: selected,
                  palette: palette,
                ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  track.artist.trim().isNotEmpty
                      ? track.artist
                      : _t(sheetContext, '未知歌手', 'Unknown artist'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? palette.accent : palette.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Text(
                  track.durationSeconds > 0
                      ? MaterialMusicSupport.formatDuration(
                          Duration(seconds: track.durationSeconds),
                        )
                      : '--:--',
                  style: TextStyle(
                    color: selected ? palette.accent : palette.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (selectedTrack == null || !context.mounted) {
      return;
    }
    await _openTrack(context, selectedTrack, localeCode);
  }

  String _targetMusicRoute(int trackId) {
    final isLyricsPage = _pageController.hasClients
        ? (_pageController.page ?? widget.initialPage.toDouble()) >= 0.5
        : widget.initialPage == 1;
    return isLyricsPage
        ? '/materials/music/lyrics/$trackId'
        : '/materials/music/player/$trackId';
  }

  Future<void> _playAdjacentTrack(
    BuildContext context,
    String localeCode, {
    required int step,
  }) async {
    final controller = ref.read(materialMusicControllerProvider.notifier);
    final beforeId = ref.read(materialMusicControllerProvider).currentItem?.id;
    if (step < 0) {
      await controller.playPrevious(localeCode: localeCode);
    } else {
      await controller.playNext(localeCode: localeCode);
    }
    if (!context.mounted) {
      return;
    }
    final current = ref.read(materialMusicControllerProvider).currentItem;
    if (current == null || current.id == beforeId) {
      return;
    }
    context.replace(
      _targetMusicRoute(current.id),
      extra: MaterialMusicRoutePayload(
        item: current,
        playlist: ref.read(materialMusicControllerProvider).playlist,
      ),
    );
  }

  Future<void> _openTrack(
    BuildContext context,
    MaterialItem track,
    String localeCode,
  ) async {
    await ref
        .read(materialMusicControllerProvider.notifier)
        .jumpToTrack(track, localeCode: localeCode);
    if (!context.mounted) {
      return;
    }
    context.replace(
      _targetMusicRoute(track.id),
      extra: MaterialMusicRoutePayload(
        item: track,
        playlist: ref.read(materialMusicControllerProvider).playlist,
      ),
    );
  }
}

class _QueueTrackArtwork extends StatelessWidget {
  const _QueueTrackArtwork({
    required this.coverUrl,
    required this.selected,
    required this.palette,
  });

  final String coverUrl;
  final bool selected;
  final _MaterialMusicPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            coverUrl.isNotEmpty
                ? CachedRemoteImage(
                    coverUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      return loadingProgress == null
                          ? child
                          : _QueueTrackArtworkFallback(
                              selected: selected,
                              palette: palette,
                            );
                    },
                    errorBuilder: (_, _, _) => _QueueTrackArtworkFallback(
                      selected: selected,
                      palette: palette,
                    ),
                  )
                : _QueueTrackArtworkFallback(
                    selected: selected,
                    palette: palette,
                  ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: selected ? 0.26 : 0.18),
                  ],
                ),
              ),
            ),
            Center(
              child: Icon(
                selected ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                color: Colors.white,
                size: selected ? 22 : 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueTrackArtworkFallback extends StatelessWidget {
  const _QueueTrackArtworkFallback({
    required this.selected,
    required this.palette,
  });

  final bool selected;
  final _MaterialMusicPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [palette.accent.withValues(alpha: 0.78), palette.accent]
              : [palette.softBackground, palette.selectedBackground],
        ),
      ),
    );
  }
}

class _MusicPlayerLoadedView extends ConsumerWidget {
  const _MusicPlayerLoadedView({
    required this.item,
    required this.player,
    required this.controllerState,
    required this.pageController,
    required this.onToggleCollect,
    required this.onDownload,
    required this.onOpenDetail,
    required this.onCyclePlayMode,
    required this.onPlayPrevious,
    required this.onTogglePlayback,
    required this.onPlayNext,
  });

  final MaterialItem item;
  final AudioPlayer player;
  final MaterialMusicState controllerState;
  final PageController pageController;
  final VoidCallback onToggleCollect;
  final VoidCallback onDownload;
  final VoidCallback onOpenDetail;
  final VoidCallback onCyclePlayMode;
  final VoidCallback onPlayPrevious;
  final VoidCallback onTogglePlayback;
  final VoidCallback onPlayNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MaterialMusicPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final coverUrl = apiClient.resolveUrl(item.coverUrl);
    final artist = item.artist.trim().isNotEmpty
        ? item.artist.trim()
        : _t(context, '未知歌手', 'Unknown artist');
    final album = item.album.trim().isNotEmpty
        ? item.album.trim()
        : _t(context, '未设置专辑', 'No album');

    return PageView(
      controller: pageController,
      children: [
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, playerSnapshot) {
            final playerState = playerSnapshot.data;
            final isPlaying = playerState?.playing ?? player.playing;
            final isBuffering =
                playerState?.processingState == ProcessingState.loading ||
                playerState?.processingState == ProcessingState.buffering;
            return StreamBuilder<Duration?>(
              stream: player.durationStream,
              builder: (context, durationSnapshot) {
                final duration = durationSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    final maxMilliseconds = math.max(
                      duration.inMilliseconds,
                      1,
                    );
                    final currentMilliseconds = position.inMilliseconds
                        .clamp(0, maxMilliseconds)
                        .toInt();
                    final lyricLines = MaterialMusicSupport.parseLyrics(
                      controllerState.lyrics,
                    );
                    final activeIndex = MaterialMusicSupport.activeLyricIndex(
                      lyricLines,
                      position,
                    );
                    final currentLyric = activeIndex >= 0
                        ? lyricLines[activeIndex].text
                        : lyricLines.isNotEmpty
                        ? lyricLines.first.text
                        : item.summary.trim().isNotEmpty
                        ? item.summary.trim()
                        : _t(
                            context,
                            '左滑查看同步歌词',
                            'Swipe left for synced lyrics',
                          );

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                      children: [
                        _MusicCoverCard(
                          palette: palette,
                          coverUrl: coverUrl,
                          onTap: onOpenDetail,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.primaryText,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$artist · $album',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.secondaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _MusicModeAction(
                              mode: controllerState.playMode,
                              palette: palette,
                              onTap: onCyclePlayMode,
                            ),
                            const SizedBox(width: 14),
                            _MusicIconAction(
                              keyValue: item.isCollected,
                              selectedIcon: Icons.favorite_rounded,
                              unselectedIcon: Icons.favorite_border_rounded,
                              color: item.isCollected
                                  ? palette.accent
                                  : palette.secondaryText,
                              backgroundColor: item.isCollected
                                  ? palette.accentSoft
                                  : palette.softBackground,
                              tooltip: item.isCollected
                                  ? _t(context, '取消收藏', 'Remove collection')
                                  : _t(context, '收藏', 'Collect'),
                              onTap: onToggleCollect,
                            ),
                            const SizedBox(width: 14),
                            _MusicIconAction(
                              keyValue: controllerState.isCached,
                              selectedIcon: Icons.check_rounded,
                              unselectedIcon: controllerState.isCaching
                                  ? Icons.downloading_rounded
                                  : Icons.download_for_offline_outlined,
                              color: controllerState.isCached
                                  ? palette.infoAccent
                                  : palette.secondaryText,
                              backgroundColor: controllerState.isCached
                                  ? palette.infoSoft
                                  : palette.softBackground,
                              tooltip: controllerState.isCached
                                  ? _t(context, '已下载', 'Downloaded')
                                  : _t(context, '下载', 'Download'),
                              onTap:
                                  controllerState.isCached ||
                                      controllerState.isCaching
                                  ? null
                                  : onDownload,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: palette.accent,
                            thumbColor: palette.accent,
                            inactiveTrackColor: palette.trackBackground,
                          ),
                          child: Slider(
                            value: currentMilliseconds.toDouble(),
                            min: 0,
                            max: maxMilliseconds.toDouble(),
                            onChanged: (next) => player.seek(
                              Duration(milliseconds: next.round()),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                MaterialMusicSupport.formatDuration(position),
                                style: TextStyle(
                                  color: palette.secondaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                MaterialMusicSupport.formatDuration(duration),
                                style: TextStyle(
                                  color: palette.secondaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _CirclePlayerButton(
                              icon: Icons.skip_previous_rounded,
                              backgroundColor: palette.softBackground,
                              foregroundColor: palette.secondaryText,
                              onTap: onPlayPrevious,
                            ),
                            const SizedBox(width: 28),
                            _CirclePlayerButton(
                              icon: isBuffering
                                  ? Icons.hourglass_top_rounded
                                  : isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 72,
                              iconSize: 38,
                              backgroundColor: palette.accent,
                              foregroundColor: Colors.white,
                              onTap: isBuffering ? null : onTogglePlayback,
                            ),
                            const SizedBox(width: 28),
                            _CirclePlayerButton(
                              icon: Icons.skip_next_rounded,
                              backgroundColor: palette.softBackground,
                              foregroundColor: palette.secondaryText,
                              onTap: onPlayNext,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          currentLyric,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.accent,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _t(
                            context,
                            '左滑查看同步歌词',
                            'Swipe left for synced lyrics',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (controllerState.errorMessage.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            controllerState.errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: palette.errorText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
        _MusicLyricsPage(
          item: item,
          player: player,
          controllerState: controllerState,
        ),
      ],
    );
  }
}

class _MusicCoverFallback extends StatelessWidget {
  const _MusicCoverFallback({required this.palette});

  final _MaterialMusicPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.accentSoft, palette.infoSoft],
        ),
      ),
      child: Center(
        child: Icon(Icons.music_note_rounded, size: 68, color: palette.accent),
      ),
    );
  }
}

class _MusicCoverCard extends StatelessWidget {
  const _MusicCoverCard({
    required this.palette,
    required this.coverUrl,
    required this.onTap,
  });

  final _MaterialMusicPalette palette;
  final String coverUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(34),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(34),
            boxShadow: palette.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  coverUrl.isNotEmpty
                      ? CachedRemoteImage(
                          coverUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                              ? child
                              : _MusicCoverFallback(palette: palette),
                          errorBuilder: (_, _, _) =>
                              _MusicCoverFallback(palette: palette),
                        )
                      : _MusicCoverFallback(palette: palette),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MusicIconAction extends StatelessWidget {
  const _MusicIconAction({
    required this.keyValue,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.color,
    required this.backgroundColor,
    required this.tooltip,
    required this.onTap,
  });

  final bool keyValue;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final Color color;
  final Color backgroundColor;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              );
              return ScaleTransition(
                scale: curved,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              keyValue ? selectedIcon : unselectedIcon,
              key: ValueKey<bool>(keyValue),
              color: color,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _MusicModeAction extends StatelessWidget {
  const _MusicModeAction({
    required this.mode,
    required this.palette,
    required this.onTap,
  });

  final MaterialMusicPlayMode mode;
  final _MaterialMusicPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      MaterialMusicPlayMode.sequential => Icons.repeat_rounded,
      MaterialMusicPlayMode.singleLoop => Icons.repeat_one_rounded,
      MaterialMusicPlayMode.shuffle => Icons.shuffle_rounded,
    };
    final label = switch (mode) {
      MaterialMusicPlayMode.sequential => _t(context, '顺序', 'Order'),
      MaterialMusicPlayMode.singleLoop => _t(context, '单曲', 'Repeat'),
      MaterialMusicPlayMode.shuffle => _t(context, '随机', 'Shuffle'),
    };

    return Tooltip(
      message: _t(context, '切换播放模式', 'Switch play mode'),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.softBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: palette.secondaryText, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MusicLyricsPage extends StatefulWidget {
  const _MusicLyricsPage({
    required this.item,
    required this.player,
    required this.controllerState,
  });

  final MaterialItem item;
  final AudioPlayer player;
  final MaterialMusicState controllerState;

  @override
  State<_MusicLyricsPage> createState() => _MusicLyricsPageState();
}

class _MusicLyricsPageState extends State<_MusicLyricsPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = <int, GlobalKey>{};
  int _lastAutoScrollIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int index) {
    return _lineKeys.putIfAbsent(index, GlobalKey.new);
  }

  void _scrollToActiveLine(int activeIndex) {
    if (activeIndex < 0 || activeIndex == _lastAutoScrollIndex) {
      return;
    }
    final targetContext = _keyFor(activeIndex).currentContext;
    if (targetContext == null) {
      return;
    }
    _lastAutoScrollIndex = activeIndex;
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialMusicPalette.of(context);
    final title = widget.item.title;
    final artist = widget.item.artist.trim().isNotEmpty
        ? widget.item.artist.trim()
        : _t(context, '未知歌手', 'Unknown artist');

    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;
        final duration = widget.player.duration ?? Duration.zero;
        final lines = MaterialMusicSupport.parseLyrics(
          widget.controllerState.lyrics,
        );
        final activeIndex = MaterialMusicSupport.activeLyricIndex(
          lines,
          position,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _scrollToActiveLine(activeIndex);
        });

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                artist,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: lines.isEmpty
                    ? Center(
                        child: Text(
                          _t(context, '暂无歌词', 'No lyrics yet'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.secondaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final active = index == activeIndex;
                          final timestamp = lines[index].time;
                          return Padding(
                            key: _keyFor(index),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: timestamp == null
                                  ? null
                                  : () => widget.player.seek(timestamp),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: Text(
                                  lines[index].text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: active
                                        ? palette.primaryText
                                        : palette.secondaryText,
                                    fontSize: active ? 26 : 18,
                                    fontWeight: active
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: palette.accent,
                  thumbColor: palette.accent,
                  inactiveTrackColor: palette.trackBackground,
                ),
                child: Slider(
                  value: position.inMilliseconds
                      .clamp(
                        0,
                        duration.inMilliseconds <= 0
                            ? 1
                            : duration.inMilliseconds,
                      )
                      .toDouble(),
                  min: 0,
                  max:
                      (duration.inMilliseconds <= 0
                              ? 1
                              : duration.inMilliseconds)
                          .toDouble(),
                  onChanged: (next) =>
                      widget.player.seek(Duration(milliseconds: next.round())),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    MaterialMusicSupport.formatDuration(position),
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    MaterialMusicSupport.formatDuration(duration),
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CirclePlayerButton extends StatelessWidget {
  const _CirclePlayerButton({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.size = 52,
    this.iconSize = 28,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Ink(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: foregroundColor, size: iconSize),
      ),
    );
  }
}

class _MaterialMusicPalette {
  const _MaterialMusicPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.bodyText,
    required this.accent,
    required this.accentSoft,
    required this.infoAccent,
    required this.infoSoft,
    required this.trackBackground,
    required this.selectedBackground,
    required this.errorText,
    required this.cardShadow,
  });

  static _MaterialMusicPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _MaterialMusicPalette(
      pageBackground: scheme.surface,
      cardBackground: isDark ? const Color(0xFF232833) : Colors.white,
      softBackground: isDark
          ? const Color(0xFF1D222D)
          : const Color(0xFFF7F7FA),
      primaryText: scheme.onSurface,
      secondaryText: isDark ? const Color(0xFF99A0AE) : const Color(0xFF7D828A),
      bodyText: isDark ? const Color(0xFFD7DAE2) : const Color(0xFF5F6570),
      accent: isDark ? const Color(0xFFB56B58) : const Color(0xFFFF9585),
      accentSoft: isDark ? const Color(0xFF34231F) : const Color(0xFFFFF0EC),
      infoAccent: isDark ? const Color(0xFFC9D8F7) : const Color(0xFF5A81DA),
      infoSoft: isDark ? const Color(0xFF232C3A) : const Color(0xFFEEF3FF),
      trackBackground: isDark
          ? const Color(0xFF313744)
          : const Color(0xFFE5E8EF),
      selectedBackground: isDark
          ? const Color(0xFF2A3040)
          : const Color(0xFFFFF3EF),
      errorText: scheme.error,
      cardShadow: isDark
          ? const <BoxShadow>[]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color bodyText;
  final Color accent;
  final Color accentSoft;
  final Color infoAccent;
  final Color infoSoft;
  final Color trackBackground;
  final Color selectedBackground;
  final Color errorText;
  final List<BoxShadow> cardShadow;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
