import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/providers/app_providers.dart';
import '../application/material_music_controller.dart';
import '../data/material_music_support.dart';

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
          onTap: () =>
              context.push('/materials/music/player/${item.id}', extra: item),
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
