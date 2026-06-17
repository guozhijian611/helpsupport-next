import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/providers/app_providers.dart';
import '../application/material_music_controller.dart';
import '../data/material_models.dart';
import '../data/material_music_support.dart';
import 'material_music_player_screen.dart';

class MaterialMusicMiniPlayerBar extends ConsumerWidget {
  const MaterialMusicMiniPlayerBar({
    super.key,
    this.compact = false,
    this.padding = const EdgeInsets.fromLTRB(14, 0, 14, 10),
  });

  final bool compact;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(materialMusicControllerProvider);
    final item = playbackState.currentItem;
    if (item == null) {
      return const SizedBox.shrink();
    }

    final palette = _MiniPlayerPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final coverUrl = apiClient.resolveUrl(item.coverUrl);
    final player = ref.watch(materialMusicAudioPlayerProvider);
    final artworkSize = compact ? 44.0 : 50.0;
    final borderRadius = compact ? 24.0 : 28.0;
    final titleFontSize = compact ? 15.0 : 16.0;
    final statusFontSize = compact ? 12.0 : 13.0;
    final actionIconSize = compact ? 22.0 : 24.0;

    return Padding(
      padding: padding,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () => context.push(
            '/materials/music/player/${item.id}',
            extra: MaterialMusicRoutePayload(
              item: item,
              playlist: playbackState.playlist,
            ),
          ),
          child: Ink(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 14,
              compact ? 12 : 14,
              compact ? 12 : 14,
              compact ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: palette.outline),
              boxShadow: palette.shadow,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: artworkSize,
                  height: artworkSize,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(compact ? 14 : 16),
                    child: coverUrl.isNotEmpty
                        ? Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              return progress == null
                                  ? child
                                  : _MiniPlayerArtworkFallback(
                                      compact: compact,
                                      palette: palette,
                                    );
                            },
                            errorBuilder: (_, _, _) =>
                                _MiniPlayerArtworkFallback(
                                  compact: compact,
                                  palette: palette,
                                ),
                          )
                        : _MiniPlayerArtworkFallback(
                            compact: compact,
                            palette: palette,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<Duration>(
                        stream: player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = player.duration ?? Duration.zero;
                          final subtitle = item.artist.trim().isNotEmpty
                              ? item.artist.trim()
                              : _t(context, '音乐播放中', 'Playing now');
                          return Text(
                            '$subtitle · ${MaterialMusicSupport.formatDuration(position)} / ${MaterialMusicSupport.formatDuration(duration)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.secondaryText,
                              fontSize: statusFontSize,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final isPlaying = playerState?.playing ?? player.playing;
                    return IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.all(compact ? 10 : 12),
                      ),
                      onPressed: () => ref
                          .read(materialMusicControllerProvider.notifier)
                          .togglePlayback(),
                      iconSize: actionIconSize,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MaterialMusicFloatingOrb extends ConsumerStatefulWidget {
  const MaterialMusicFloatingOrb({super.key, required this.bottomInset});

  final double bottomInset;

  @override
  ConsumerState<MaterialMusicFloatingOrb> createState() =>
      _MaterialMusicFloatingOrbState();
}

class _MaterialMusicFloatingOrbState
    extends ConsumerState<MaterialMusicFloatingOrb>
    with TickerProviderStateMixin {
  Offset? _offset;
  bool _expanded = false;
  bool _orbAnimating = false;

  late final AnimationController _rotationController;
  late final AnimationController _pulseController;

  static const double _collapsedSize = 66;
  static const double _expandedWidth = 248;
  static const double _expandedHeight = 80;
  static const double _edgeMargin = 16;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _syncOrbAnimation(bool shouldAnimate) {
    if (_orbAnimating == shouldAnimate) {
      return;
    }
    _orbAnimating = shouldAnimate;
    if (shouldAnimate) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
      return;
    }
    _rotationController.stop();
    _pulseController.stop();
    _rotationController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    _pulseController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _openPlayer(MaterialMusicState playbackState, MaterialItem item) {
    if (!mounted) {
      return;
    }
    GoRouter.of(context).push(
      '/materials/music/player/${item.id}',
      extra: MaterialMusicRoutePayload(
        item: item,
        playlist: List<MaterialItem>.from(playbackState.playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(materialMusicControllerProvider);
    final item = playbackState.currentItem;
    if (item == null) {
      return const SizedBox.shrink();
    }

    final palette = _MiniPlayerPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final coverUrl = apiClient.resolveUrl(item.coverUrl);
    final player = ref.watch(materialMusicAudioPlayerProvider);
    final width = _expanded ? _expandedWidth : _collapsedSize;
    final height = _expanded ? _expandedHeight : _collapsedSize;

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final isPlaying = playerState?.playing ?? player.playing;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _syncOrbAnimation(isPlaying);
        });
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxX = (constraints.maxWidth - width - _edgeMargin).clamp(
              0.0,
              double.infinity,
            );
            final maxY = (constraints.maxHeight - height - widget.bottomInset)
                .clamp(0.0, double.infinity);
            final defaultOffset = Offset(maxX, maxY);
            final current = _offset ?? defaultOffset;
            final safeOffset = Offset(
              current.dx.clamp(0.0, maxX),
              current.dy.clamp(0.0, maxY),
            );
            if (_offset != null && safeOffset != _offset) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                setState(() => _offset = safeOffset);
              });
            }

            return Stack(
              children: [
                Positioned(
                  left: safeOffset.dx,
                  top: safeOffset.dy,
                  child: Material(
                    type: MaterialType.transparency,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final next = Offset(
                          (safeOffset.dx + details.delta.dx).clamp(0.0, maxX),
                          (safeOffset.dy + details.delta.dy).clamp(0.0, maxY),
                        );
                        setState(() => _offset = next);
                      },
                      onTap: _expanded
                          ? null
                          : () => setState(() => _expanded = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: width,
                        height: height,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: palette.cardBackground,
                          borderRadius: BorderRadius.circular(
                            _expanded ? 28 : _collapsedSize / 2,
                          ),
                          border: Border.all(color: palette.outline),
                          boxShadow: palette.shadow,
                        ),
                        padding: _expanded
                            ? const EdgeInsets.fromLTRB(10, 8, 10, 10)
                            : EdgeInsets.zero,
                        child: _expanded
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: _expandedWidth - 20,
                                  height: _expandedHeight - 16,
                                  child: _ExpandedOrbContent(
                                    key: ValueKey<int>(item.id),
                                    itemTitle: item.title,
                                    itemArtist: item.artist.trim().isNotEmpty
                                        ? item.artist.trim()
                                        : _t(context, '音乐播放中', 'Playing now'),
                                    palette: palette,
                                    player: player,
                                    rotatingArtwork: _buildOrbArtwork(
                                      coverUrl: coverUrl,
                                      palette: palette,
                                      collapsed: false,
                                    ),
                                    onOpenPlayer: () =>
                                        _openPlayer(playbackState, item),
                                    onClose: () async {
                                      await ref
                                          .read(
                                            materialMusicControllerProvider
                                                .notifier,
                                          )
                                          .clearPlayback();
                                      if (!mounted) {
                                        return;
                                      }
                                      setState(() => _expanded = false);
                                    },
                                    onCollapse: () =>
                                        setState(() => _expanded = false),
                                  ),
                                ),
                              )
                            : _buildOrbArtwork(
                                coverUrl: coverUrl,
                                palette: palette,
                                collapsed: true,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOrbArtwork({
    required String coverUrl,
    required _MiniPlayerPalette palette,
    required bool collapsed,
  }) {
    final artwork = coverUrl.isNotEmpty
        ? Image.network(
            coverUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              return progress == null
                  ? child
                  : _MiniPlayerArtworkFallback(
                      compact: false,
                      palette: palette,
                    );
            },
            errorBuilder: (_, _, _) =>
                _MiniPlayerArtworkFallback(compact: false, palette: palette),
          )
        : _MiniPlayerArtworkFallback(compact: false, palette: palette);

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      child: ClipOval(child: artwork),
      builder: (context, child) {
        final glowAlpha = collapsed
            ? 0.14 + _pulseController.value * 0.18
            : 0.08 + _pulseController.value * 0.12;
        final blurRadius = collapsed
            ? (24 + _pulseController.value * 10).toDouble()
            : 14.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: glowAlpha),
                blurRadius: blurRadius,
                spreadRadius: (1 + _pulseController.value * 1.5).toDouble(),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: _rotationController.value * math.pi * 2,
            child: child,
          ),
        );
      },
    );
  }
}

class _ExpandedOrbContent extends ConsumerWidget {
  const _ExpandedOrbContent({
    super.key,
    required this.itemTitle,
    required this.itemArtist,
    required this.palette,
    required this.player,
    required this.rotatingArtwork,
    required this.onOpenPlayer,
    required this.onClose,
    required this.onCollapse,
  });

  final String itemTitle;
  final String itemArtist;
  final _MiniPlayerPalette palette;
  final AudioPlayer player;
  final Widget rotatingArtwork;
  final VoidCallback onOpenPlayer;
  final VoidCallback onClose;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = Localizations.localeOf(context).toLanguageTag();

    return Row(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onOpenPlayer,
          child: SizedBox(width: 54, height: 54, child: rotatingArtwork),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onCollapse,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  itemArtist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final isPlaying = playerState?.playing ?? player.playing;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: isPlaying
                      ? _t(context, '暂停', 'Pause')
                      : _t(context, '播放', 'Play'),
                  onPressed: () => ref
                      .read(materialMusicControllerProvider.notifier)
                      .togglePlayback(),
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: palette.accent,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: _t(context, '下一首', 'Next track'),
                  onPressed: () => ref
                      .read(materialMusicControllerProvider.notifier)
                      .playNext(localeCode: localeCode),
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: palette.secondaryText,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: _t(context, '关闭', 'Close'),
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, color: palette.secondaryText),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MiniPlayerArtworkFallback extends StatelessWidget {
  const _MiniPlayerArtworkFallback({
    required this.compact,
    required this.palette,
  });

  final bool compact;
  final _MiniPlayerPalette palette;

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
        child: Icon(
          Icons.music_note_rounded,
          size: compact ? 22 : 26,
          color: palette.accent,
        ),
      ),
    );
  }
}

class _MiniPlayerPalette {
  const _MiniPlayerPalette({
    required this.cardBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.accentSoft,
    required this.infoSoft,
    required this.outline,
    required this.shadow,
  });

  static _MiniPlayerPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _MiniPlayerPalette(
      cardBackground: isDark
          ? const Color(0xFF232833).withValues(alpha: 0.96)
          : Colors.white.withValues(alpha: 0.98),
      primaryText: scheme.onSurface,
      secondaryText: isDark ? const Color(0xFF99A0AE) : const Color(0xFF7D828A),
      accent: isDark ? const Color(0xFFFFB4A8) : const Color(0xFFFF9585),
      accentSoft: isDark ? const Color(0xFF34231F) : const Color(0xFFFFF0EC),
      infoSoft: isDark ? const Color(0xFF232C3A) : const Color(0xFFEEF3FF),
      outline: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFF1E5E0),
      shadow: isDark
          ? const <BoxShadow>[]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
    );
  }

  final Color cardBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color accentSoft;
  final Color infoSoft;
  final Color outline;
  final List<BoxShadow> shadow;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
