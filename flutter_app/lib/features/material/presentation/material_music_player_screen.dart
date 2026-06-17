import 'dart:math' as math;

import 'package:flutter/material.dart' hide MaterialPage;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/material_controller.dart';
import '../application/material_music_controller.dart';
import '../data/material_models.dart';
import '../data/material_music_support.dart';

class MaterialMusicPlayerScreen extends ConsumerWidget {
  const MaterialMusicPlayerScreen({
    super.key,
    required this.materialId,
    this.initialItem,
  });

  final int materialId;
  final MaterialItem? initialItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final localeCode = Localizations.localeOf(context).languageCode;
    final detailQuery = MaterialDetailQuery(id: materialId, locale: localeTag);
    final detail = ref.watch(materialDetailProvider(detailQuery));
    final controllerState = ref.watch(materialMusicControllerProvider);
    final controller = ref.read(materialMusicControllerProvider.notifier);
    final player = ref.watch(materialMusicAudioPlayerProvider);

    final fallback = controllerState.currentItem?.id == materialId
        ? controllerState.currentItem
        : initialItem;
    final detailItem = detail.maybeWhen(
      data: (item) => item,
      orElse: () => fallback,
    );

    if (detailItem != null && MaterialMusicSupport.isAudioItem(detailItem)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.syncCurrentItem(detailItem);
      });
    }

    final activeItem =
        controllerState.currentItem != null &&
            controllerState.currentItem!.id == materialId
        ? controllerState.currentItem
        : detailItem;

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

    if (activeItem != null &&
        MaterialMusicSupport.isAudioItem(activeItem) &&
        playlist.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.syncPlaylist(playlist.value?.list ?? const <MaterialItem>[]);
        controller.openTrack(
          activeItem,
          localeCode: localeCode,
          playlist: playlist.value?.list,
          autoplay: true,
        );
      });
    } else if (activeItem != null &&
        MaterialMusicSupport.isAudioItem(activeItem)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.openTrack(
          activeItem,
          localeCode: localeCode,
          autoplay: true,
        );
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
                : () => _showQueueSheet(context, ref, localeCode),
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
            onToggleCollect: () => _toggleCollect(
              context,
              ref,
              localeTag: localeTag,
              localeCode: localeCode,
              item: activeItem ?? detailData,
            ),
            onDownload: () => _cacheCurrentTrack(context, ref, localeCode),
            onOpenLyrics: () => _openLyrics(context, activeItem ?? detailData),
            onOpenOverview: () => _openDetailSection(
              context,
              activeItem ?? detailData,
              'overview',
            ),
            onOpenComments: () => _openDetailSection(
              context,
              activeItem ?? detailData,
              'comments',
            ),
            onPlayPrevious: () =>
                _playAdjacentTrack(context, ref, localeCode, step: -1),
            onTogglePlayback: controller.togglePlayback,
            onPlayNext: () =>
                _playAdjacentTrack(context, ref, localeCode, step: 1),
          ),
          error: (error, _) => activeItem == null
              ? Center(child: Text(error.toString()))
              : _MusicPlayerLoadedView(
                  item: activeItem,
                  player: player,
                  controllerState: controllerState,
                  onToggleCollect: () => _toggleCollect(
                    context,
                    ref,
                    localeTag: localeTag,
                    localeCode: localeCode,
                    item: activeItem,
                  ),
                  onDownload: () =>
                      _cacheCurrentTrack(context, ref, localeCode),
                  onOpenLyrics: () => _openLyrics(context, activeItem),
                  onOpenOverview: () =>
                      _openDetailSection(context, activeItem, 'overview'),
                  onOpenComments: () =>
                      _openDetailSection(context, activeItem, 'comments'),
                  onPlayPrevious: () =>
                      _playAdjacentTrack(context, ref, localeCode, step: -1),
                  onTogglePlayback: controller.togglePlayback,
                  onPlayNext: () =>
                      _playAdjacentTrack(context, ref, localeCode, step: 1),
                ),
          loading: () => activeItem == null
              ? const Center(child: CircularProgressIndicator())
              : _MusicPlayerLoadedView(
                  item: activeItem,
                  player: player,
                  controllerState: controllerState,
                  onToggleCollect: () => _toggleCollect(
                    context,
                    ref,
                    localeTag: localeTag,
                    localeCode: localeCode,
                    item: activeItem,
                  ),
                  onDownload: () =>
                      _cacheCurrentTrack(context, ref, localeCode),
                  onOpenLyrics: () => _openLyrics(context, activeItem),
                  onOpenOverview: () =>
                      _openDetailSection(context, activeItem, 'overview'),
                  onOpenComments: () =>
                      _openDetailSection(context, activeItem, 'comments'),
                  onPlayPrevious: () =>
                      _playAdjacentTrack(context, ref, localeCode, step: -1),
                  onTogglePlayback: controller.togglePlayback,
                  onPlayNext: () =>
                      _playAdjacentTrack(context, ref, localeCode, step: 1),
                ),
        ),
      ),
    );
  }

  Future<void> _toggleCollect(
    BuildContext context,
    WidgetRef ref, {
    required String localeTag,
    required String localeCode,
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
    WidgetRef ref,
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
    if (after.isCached) {
      context.showCenteredNotice(_t(context, '已下载到本地', 'Downloaded offline'));
    } else if (after.errorMessage.trim().isNotEmpty) {
      context.showCenteredNotice(after.errorMessage);
    }
  }

  void _openLyrics(BuildContext context, MaterialItem item) {
    context.push('/materials/music/lyrics/${item.id}', extra: item);
  }

  void _openDetailSection(
    BuildContext context,
    MaterialItem item,
    String section,
  ) {
    context.push('/materials/detail/${item.id}?section=$section', extra: item);
  }

  Future<void> _showQueueSheet(
    BuildContext context,
    WidgetRef ref,
    String localeCode,
  ) async {
    final state = ref.read(materialMusicControllerProvider);
    final activeId = state.currentItem?.id ?? 0;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _MaterialMusicPalette.of(context).cardBackground,
      showDragHandle: true,
      builder: (sheetContext) {
        final palette = _MaterialMusicPalette.of(sheetContext);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
          itemCount: state.playlist.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                    : () async {
                        Navigator.of(sheetContext).pop();
                        await _openTrack(context, ref, track, localeCode);
                      },
                leading: CircleAvatar(
                  backgroundColor: selected
                      ? palette.accent
                      : palette.pageBackground,
                  foregroundColor: selected ? Colors.white : palette.accent,
                  child: Icon(
                    selected
                        ? Icons.graphic_eq_rounded
                        : Icons.music_note_rounded,
                  ),
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
  }

  Future<void> _playAdjacentTrack(
    BuildContext context,
    WidgetRef ref,
    String localeCode, {
    required int step,
  }) async {
    final state = ref.read(materialMusicControllerProvider);
    final current = state.currentItem;
    if (current == null || state.playlist.isEmpty) {
      return;
    }
    final currentIndex = state.playlist.indexWhere(
      (item) => item.id == current.id,
    );
    if (currentIndex < 0) {
      return;
    }
    final nextIndex = currentIndex + step;
    if (nextIndex < 0 || nextIndex >= state.playlist.length) {
      return;
    }
    await _openTrack(context, ref, state.playlist[nextIndex], localeCode);
  }

  Future<void> _openTrack(
    BuildContext context,
    WidgetRef ref,
    MaterialItem track,
    String localeCode,
  ) async {
    await ref
        .read(materialMusicControllerProvider.notifier)
        .jumpToTrack(track, localeCode: localeCode);
    if (!context.mounted) {
      return;
    }
    context.replace('/materials/music/player/${track.id}', extra: track);
  }
}

class _MusicPlayerLoadedView extends ConsumerWidget {
  const _MusicPlayerLoadedView({
    required this.item,
    required this.player,
    required this.controllerState,
    required this.onToggleCollect,
    required this.onDownload,
    required this.onOpenLyrics,
    required this.onOpenOverview,
    required this.onOpenComments,
    required this.onPlayPrevious,
    required this.onTogglePlayback,
    required this.onPlayNext,
  });

  final MaterialItem item;
  final AudioPlayer player;
  final MaterialMusicState controllerState;
  final VoidCallback onToggleCollect;
  final VoidCallback onDownload;
  final VoidCallback onOpenLyrics;
  final VoidCallback onOpenOverview;
  final VoidCallback onOpenComments;
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

    return StreamBuilder<PlayerState>(
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
                final maxMilliseconds = math.max(duration.inMilliseconds, 1);
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
                    : item.summary.isNotEmpty
                    ? item.summary
                    : _t(
                        context,
                        '点击封面查看歌曲介绍和评论区',
                        'Tap cover to view details and comments',
                      );
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  children: [
                    GestureDetector(
                      onTap: onOpenOverview,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: palette.cardBackground,
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: palette.cardShadow,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 286,
                              height: 286,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                color: palette.softBackground,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  coverUrl.isNotEmpty
                                      ? Image.network(
                                          coverUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (_, child, progress) =>
                                                  progress == null
                                                  ? child
                                                  : _MusicCoverFallback(
                                                      palette: palette,
                                                    ),
                                          errorBuilder: (_, _, _) =>
                                              _MusicCoverFallback(
                                                palette: palette,
                                              ),
                                        )
                                      : _MusicCoverFallback(palette: palette),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.18),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        color: palette.accent,
                                        size: 42,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                    child: Text(
                                      _t(
                                        context,
                                        '点按封面进入 歌曲介绍 + 评论区',
                                        'Tap cover to open details and comments',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                _MusicActionChip(
                                  icon: item.isCollected
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  label: item.isCollected
                                      ? _t(context, '已收藏', 'Collected')
                                      : _t(context, '收藏', 'Collect'),
                                  accent: palette.accent,
                                  backgroundColor: item.isCollected
                                      ? palette.accentSoft
                                      : palette.softBackground,
                                  onTap: onToggleCollect,
                                ),
                                _MusicActionChip(
                                  icon: controllerState.isCached
                                      ? Icons.download_done_rounded
                                      : controllerState.isCaching
                                      ? Icons.downloading_rounded
                                      : Icons.download_for_offline_outlined,
                                  label: controllerState.isCached
                                      ? _t(context, '已下载本地', 'Downloaded')
                                      : controllerState.isCaching
                                      ? _t(
                                          context,
                                          '下载中 ${controllerState.cacheProgress.clamp(0, 100).toStringAsFixed(0)}%',
                                          'Downloading ${controllerState.cacheProgress.clamp(0, 100).toStringAsFixed(0)}%',
                                        )
                                      : _t(
                                          context,
                                          '下载到本地',
                                          'Download offline',
                                        ),
                                  accent: palette.infoAccent,
                                  backgroundColor: controllerState.isCached
                                      ? palette.infoSoft
                                      : palette.softBackground,
                                  onTap:
                                      controllerState.isCached ||
                                          controllerState.isCaching
                                      ? null
                                      : onDownload,
                                ),
                                _MusicActionChip(
                                  icon: Icons.lyrics_outlined,
                                  label: _t(context, '歌词', 'Lyrics'),
                                  accent: palette.secondaryText,
                                  backgroundColor: palette.softBackground,
                                  onTap: onOpenLyrics,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _MusicEntryButton(
                            title: _t(context, '歌曲介绍', 'Overview'),
                            subtitle: _t(
                              context,
                              '专辑说明 / 场景标签',
                              'Album note / scene tags',
                            ),
                            onTap: onOpenOverview,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MusicEntryButton(
                            title: _t(context, '评论区', 'Comments'),
                            subtitle: _t(
                              context,
                              '热评 / 最新 / 写评论',
                              'Top / latest / write',
                            ),
                            onTap: onOpenComments,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (item.summary.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(
                          color: palette.softBackground,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          item.summary,
                          style: TextStyle(
                            color: palette.bodyText,
                            fontSize: 14,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
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
                        onChanged: (next) =>
                            player.seek(Duration(milliseconds: next.round())),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
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

class _MusicActionChip extends StatelessWidget {
  const _MusicActionChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: accent, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicEntryButton extends StatelessWidget {
  const _MusicEntryButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialMusicPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: palette.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: palette.secondaryText,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
