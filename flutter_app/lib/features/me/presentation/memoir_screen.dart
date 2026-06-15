import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/me_content_controller.dart';
import '../data/me_content_models.dart';

class MemoirScreen extends ConsumerWidget {
  const MemoirScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MemoirPalette.of(context);
    final memoirs = ref.watch(memoirItemsProvider);
    final configs = ref.watch(memoirConfigsProvider);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(_t(context, '回忆录', 'Memoir')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(memoirItemsProvider);
            ref.invalidate(memoirConfigsProvider);
            await Future.wait([
              ref.read(memoirItemsProvider.future),
              ref.read(memoirConfigsProvider.future),
            ]);
          },
          child: memoirs.when(
            data: (page) {
              if (page.list.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  children: [
                    const _MemoirHeroCard(),
                    const SizedBox(height: 16),
                    configs.when(
                      data: (items) => _MemoirConfigPanel(configs: items),
                      error: (error, _) => _EmptyPanel(
                        title: _t(context, '还没有回忆录', 'No memoirs yet'),
                        subtitle: error.toString(),
                      ),
                      loading: () => const _PanelSkeleton(height: 180),
                    ),
                  ],
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemCount: page.list.length,
                itemBuilder: (context, index) =>
                    _MemoirCard(item: page.list[index]),
              );
            },
            error: (error, _) => ListView(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(error.toString()),
                  ),
                ),
              ],
            ),
            loading: () => const _MemoirGridSkeleton(),
          ),
        ),
      ),
    );
  }
}

class MemoirDetailScreen extends ConsumerWidget {
  const MemoirDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MemoirPalette.of(context);
    final detail = ref.watch(memoirDetailProvider(id));

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(_t(context, '回忆录详情', 'Memoir detail')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: detail.when(
          data: (item) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _MemoirHeroCard(item: item),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: palette.cardBackground,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetaChip(
                          label: item.sourceMonth.isEmpty
                              ? '--'
                              : item.sourceMonth,
                        ),
                        _MetaChip(
                          label: _t(
                            context,
                            '${item.journalCount} 篇日记',
                            '${item.journalCount} journals',
                          ),
                        ),
                        if (item.grantLevelName.isNotEmpty)
                          _MetaChip(label: item.grantLevelName),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.description.isNotEmpty
                          ? item.description
                          : _t(
                              context,
                              '系统会根据你的日记、任务与成长阶段生成这份回忆录。',
                              'This memoir is generated from your journals, tasks, and progress.',
                            ),
                      style: TextStyle(
                        color: palette.bodyText,
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),
                    if (item.videoUrl.trim().isNotEmpty) ...[
                      const SizedBox(height: 18),
                      FilledButton.tonalIcon(
                        onPressed: () => _openVideo(context, item.videoUrl),
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        label: Text(_t(context, '打开回忆视频', 'Open memoir video')),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _openVideo(BuildContext context, String videoUrl) async {
    final uri = Uri.tryParse(videoUrl.trim());
    if (uri == null) {
      context.showCenteredNotice(_t(context, '视频地址无效', 'Invalid video URL'));
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      context.showCenteredNotice(
        _t(context, '无法打开视频链接', 'Unable to open video'),
      );
    }
  }
}

class _MemoirCard extends ConsumerWidget {
  const _MemoirCard({required this.item});

  final MemoirItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MemoirPalette.of(context);
    final url = ref.watch(apiClientProvider).resolveUrl(item.cover);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MemoirDetailScreen(id: item.id)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _MemoirCoverPlaceholder(item: item),
                      )
                    : _MemoirCoverPlaceholder(item: item),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _t(
                context,
                '时间：${item.sourceMonth.isEmpty ? item.createTime : item.sourceMonth}',
                'Date: ${item.sourceMonth.isEmpty ? item.createTime : item.sourceMonth}',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoirHeroCard extends ConsumerWidget {
  const _MemoirHeroCard({this.item});

  final MemoirItem? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(apiClientProvider).resolveUrl(item?.cover ?? '');

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF173A7C), Color(0xFF2A6CB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: url.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
                onError: (_, _) {},
              )
            : null,
      ),
      child: item == null
          ? const SizedBox.shrink()
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.28),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  item!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
    );
  }
}

class _MemoirCoverPlaceholder extends StatelessWidget {
  const _MemoirCoverPlaceholder({required this.item});

  final MemoirItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF173A7C), Color(0xFF25569C), Color(0xFF2B8AD1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -30,
            bottom: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE9D36A), width: 8),
              ),
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.sourceMonth.isEmpty
                      ? 'Memoir'
                      : item.sourceMonth.replaceAll('-', '.'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 110,
                  child: Text(
                    item.title,
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoirConfigPanel extends StatelessWidget {
  const _MemoirConfigPanel({required this.configs});

  final List<MemoirConfig> configs;

  @override
  Widget build(BuildContext context) {
    final palette = _MemoirPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, '回忆录生成规则', 'Memoir generation rules'),
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (configs.isEmpty)
            Text(
              _t(
                context,
                '当累计的日记和任务达到条件后，系统会自动生成回忆录。',
                'A memoir will be generated automatically once your journals and tasks meet the rule.',
              ),
              style: TextStyle(color: palette.secondaryText, height: 1.6),
            )
          else
            ...configs.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.stars_rounded,
                        size: 18,
                        color: Color(0xFFFFAE4D),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t(
                          context,
                          '${item.name}：至少 ${item.minJournalCount} 篇日记，${_cycleLabel(context, item.generationCycle)}生成',
                          '${item.name}: at least ${item.minJournalCount} journals, ${_cycleLabel(context, item.generationCycle)} generation',
                        ),
                        style: TextStyle(color: palette.bodyText, height: 1.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _MemoirPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.bodyText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = _MemoirPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFD0D3DA),
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.secondaryText, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MemoirGridSkeleton extends StatelessWidget {
  const _MemoirGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => const _PanelSkeleton(height: 280),
    );
  }
}

class _PanelSkeleton extends StatelessWidget {
  const _PanelSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = _MemoirPalette.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }
}

String _cycleLabel(BuildContext context, String value) {
  return switch (value) {
    'weekly' => _t(context, '每周', 'weekly'),
    'quarterly' => _t(context, '每季度', 'quarterly'),
    _ => _t(context, '每月', 'monthly'),
  };
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _MemoirPalette {
  const _MemoirPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.bodyText,
  });

  factory _MemoirPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _MemoirPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      softBackground: scheme.surfaceContainerLow,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      bodyText: isDark
          ? scheme.onSurface.withValues(alpha: 0.84)
          : const Color(0xFF4A4D55),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color bodyText;
}
