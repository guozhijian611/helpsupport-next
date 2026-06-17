import 'package:flutter/material.dart' hide MaterialPage;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/material_controller.dart';
import '../application/material_music_controller.dart';
import '../data/material_models.dart';
import '../data/material_music_support.dart';

class MaterialMusicLyricsScreen extends ConsumerWidget {
  const MaterialMusicLyricsScreen({
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

    final detailItem = detail.maybeWhen(
      data: (item) => item,
      orElse: () => controllerState.currentItem?.id == materialId
          ? controllerState.currentItem
          : initialItem,
    );

    if (detailItem != null && MaterialMusicSupport.isAudioItem(detailItem)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.openTrack(
          detailItem,
          localeCode: localeCode,
          autoplay: true,
        );
      });
    }

    final activeItem = controllerState.currentItem?.id == materialId
        ? controllerState.currentItem
        : detailItem;
    final palette = _LyricsPalette.of(context);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(_t(context, '歌词', 'Lyrics')),
      ),
      body: SafeArea(
        child: activeItem == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final duration = player.duration ?? Duration.zero;
                  final lines = MaterialMusicSupport.parseLyrics(
                    controllerState.lyrics,
                  );
                  final activeIndex = MaterialMusicSupport.activeLyricIndex(
                    lines,
                    position,
                  );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    children: [
                      Text(
                        activeItem.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activeItem.artist.trim().isNotEmpty
                            ? activeItem.artist
                            : _t(context, '未知歌手', 'Unknown artist'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.secondaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          _LyricsChip(
                            label: activeItem.isCollected
                                ? _t(context, '已收藏', 'Collected')
                                : _t(context, '收藏', 'Collect'),
                            backgroundColor: activeItem.isCollected
                                ? palette.accentSoft
                                : palette.softBackground,
                            color: activeItem.isCollected
                                ? palette.accent
                                : palette.secondaryText,
                          ),
                          _LyricsChip(
                            label: controllerState.isCached
                                ? _t(context, '已下载到本地', 'Downloaded')
                                : _t(context, '在线播放', 'Streaming'),
                            backgroundColor: controllerState.isCached
                                ? palette.infoSoft
                                : palette.softBackground,
                            color: controllerState.isCached
                                ? palette.infoAccent
                                : palette.secondaryText,
                          ),
                          _LyricsChip(
                            label: _t(context, '返回播放器', 'Back to player'),
                            backgroundColor: palette.softBackground,
                            color: palette.secondaryText,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      if (lines.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 80),
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
                      else
                        for (var index = 0; index < lines.length; index += 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              lines[index].text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: index == activeIndex
                                    ? palette.primaryText
                                    : palette.secondaryText,
                                fontSize: index == activeIndex ? 26 : 18,
                                fontWeight: index == activeIndex
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(
                          color: palette.softBackground,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          _t(
                            context,
                            '默认高亮当前句，向下滑仍可查看完整歌词。',
                            'The active line stays highlighted while you can still browse the full lyrics.',
                          ),
                          style: TextStyle(
                            color: palette.secondaryText,
                            height: 1.55,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                              player.seek(Duration(milliseconds: next.round())),
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
                  );
                },
              ),
      ),
    );
  }
}

class _LyricsChip extends StatelessWidget {
  const _LyricsChip({
    required this.label,
    required this.backgroundColor,
    required this.color,
    this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _LyricsPalette {
  const _LyricsPalette({
    required this.pageBackground,
    required this.softBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.accentSoft,
    required this.infoAccent,
    required this.infoSoft,
    required this.trackBackground,
  });

  static _LyricsPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _LyricsPalette(
      pageBackground: scheme.surface,
      softBackground: isDark
          ? const Color(0xFF232833)
          : const Color(0xFFF7F7FA),
      primaryText: scheme.onSurface,
      secondaryText: isDark ? const Color(0xFF8F95A3) : const Color(0xFFA3A8B0),
      accent: isDark ? const Color(0xFFB56B58) : const Color(0xFFFF9585),
      accentSoft: isDark ? const Color(0xFF34231F) : const Color(0xFFFFF0EC),
      infoAccent: isDark ? const Color(0xFFC9D8F7) : const Color(0xFF5A81DA),
      infoSoft: isDark ? const Color(0xFF232C3A) : const Color(0xFFEEF3FF),
      trackBackground: isDark
          ? const Color(0xFF313744)
          : const Color(0xFFE5E8EF),
    );
  }

  final Color pageBackground;
  final Color softBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color accentSoft;
  final Color infoAccent;
  final Color infoSoft;
  final Color trackBackground;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
