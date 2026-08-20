import 'package:flutter/material.dart';
import 'package:helpsupport_app/core/cache/cached_remote_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/l10n_extensions.dart';
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
        title: Text(context.l10n.meMemoir),
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
              final configPanel = configs.when(
                data: (items) => _MemoirConfigPanel(configs: items),
                error: (error, _) => _EmptyPanel(
                  title: context.l10n.meMemoirRulesTitle,
                  subtitle: error.toString(),
                ),
                loading: () => const _PanelSkeleton(height: 180),
              );
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    sliver: SliverToBoxAdapter(child: configPanel),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        context.l10n.meMemoirHistoryTitle,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (page.list.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                      sliver: SliverToBoxAdapter(
                        child: _EmptyPanel(
                          title: context.l10n.meMemoirEmptyTitle,
                          subtitle: context.l10n.meMemoirEmptySubtitle,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.68,
                            ),
                        itemCount: page.list.length,
                        itemBuilder: (context, index) =>
                            _MemoirCard(item: page.list[index]),
                      ),
                    ),
                ],
              );
            },
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
        title: Text(context.l10n.meMemoirDetailTitle),
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
                          label: context.l10n.meMemoirJournalCount(
                            item.journalCount,
                          ),
                        ),
                        if (item.grantLevelName.isNotEmpty)
                          _MetaChip(label: item.grantLevelName),
                        if (item.configName.isNotEmpty &&
                            item.configName != item.grantLevelName)
                          _MetaChip(label: item.configName),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.description.isNotEmpty
                          ? item.description
                          : context.l10n.meMemoirDefaultDescription,
                      style: TextStyle(
                        color: palette.bodyText,
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),
                    if (item.sourceMaterials.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _SourceMaterialsPanel(item: item),
                    ],
                    if (item.videoUrl.trim().isNotEmpty) ...[
                      const SizedBox(height: 18),
                      FilledButton.tonalIcon(
                        onPressed: () => _openVideo(context, item.videoUrl),
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        label: Text(context.l10n.meMemoirOpenVideo),
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
      context.showCenteredNotice(context.l10n.meMemoirVideoInvalid);
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      context.showCenteredNotice(
        context.l10n.meMemoirVideoOpenFailed,
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
                    ? CachedRemoteImage(
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
              item.title.isNotEmpty
                  ? item.title
                  : context.l10n.meMemoirDateLabel(
                      item.sourceMonth.isEmpty
                          ? item.createTime
                          : item.sourceMonth,
                    ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoirHeroCard extends ConsumerWidget {
  const _MemoirHeroCard({required this.item});

  final MemoirItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(apiClientProvider).resolveUrl(item.cover);

    return Container(
      height: 250,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url.isNotEmpty)
            CachedRemoteImage(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _MemoirCoverPlaceholder(item: item),
            )
          else
            _MemoirCoverPlaceholder(item: item),
          Container(
            decoration: BoxDecoration(
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
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
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
            child: Text(
              item.sourceMonth.isEmpty
                  ? context.l10n.meMemoir
                  : item.sourceMonth.replaceAll('-', '.'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoirConfigPanel extends ConsumerStatefulWidget {
  const _MemoirConfigPanel({required this.configs});

  final List<MemoirConfig> configs;

  @override
  ConsumerState<_MemoirConfigPanel> createState() => _MemoirConfigPanelState();
}

class _MemoirConfigPanelState extends ConsumerState<_MemoirConfigPanel> {
  int? _generatingConfigId;

  @override
  Widget build(BuildContext context) {
    final palette = _MemoirPalette.of(context);
    final configs = widget.configs;
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
            context.l10n.meMemoirRulesTitle,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (configs.isEmpty)
            Text(
              context.l10n.meMemoirRulesHint,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _ruleText(context, item),
                            style: TextStyle(
                              color: palette.bodyText,
                              height: 1.55,
                            ),
                          ),
                          if (item.canGenerate) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _generatingConfigId == null
                                    ? () => _generate(context, item)
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: palette.accent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: palette.accent
                                      .withValues(alpha: 0.45),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: _generatingConfigId == item.id
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome_rounded),
                                label: Text(context.l10n.meMemoirGenerate),
                              ),
                            ),
                          ] else if (item.existingMemoirId > 0) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _openExisting(
                                  context,
                                  item.existingMemoirId,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: palette.accent,
                                  side: BorderSide(color: palette.accent),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.menu_book_rounded),
                                label: Text(context.l10n.meMemoirView),
                              ),
                            ),
                          ] else if (item.reason.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              _reasonText(context, item),
                              style: TextStyle(
                                color: palette.secondaryText,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
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

  Future<void> _generate(BuildContext context, MemoirConfig config) async {
    setState(() => _generatingConfigId = config.id);
    try {
      final item = await ref
          .read(meContentRepositoryProvider)
          .generateMemoir(configId: config.id);
      ref.invalidate(memoirItemsProvider);
      ref.invalidate(memoirConfigsProvider);
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(context.l10n.meMemoirGenerated);
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MemoirDetailScreen(id: item.id)),
      );
    } catch (error) {
      if (context.mounted) {
        context.showCenteredNotice(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _generatingConfigId = null);
      }
    }
  }

  void _openExisting(BuildContext context, int memoirId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MemoirDetailScreen(id: memoirId)),
    );
  }
}

class _SourceMaterialsPanel extends StatelessWidget {
  const _SourceMaterialsPanel({required this.item});

  final MemoirItem item;

  @override
  Widget build(BuildContext context) {
    final palette = _MemoirPalette.of(context);
    final groups = <_SourceMaterialGroup>[
      _SourceMaterialGroup(
        title: _t(context, '日记素材', 'Journal sources'),
        rows: _sourceRows(item.sourceMaterials['journals']),
      ),
      _SourceMaterialGroup(
        title: _t(context, '任务素材', 'Task sources'),
        rows: _sourceRows(item.sourceMaterials['tasks']),
      ),
      _SourceMaterialGroup(
        title: _t(context, '学习记录', 'Learning history'),
        rows: _sourceRows(item.sourceMaterials['material_history']),
      ),
      _SourceMaterialGroup(
        title: _t(context, '收藏素材', 'Saved materials'),
        rows: _sourceRows(item.sourceMaterials['material_collect']),
      ),
      _SourceMaterialGroup(
        title: _t(context, '私人素材', 'Private materials'),
        rows: _sourceRows(item.sourceMaterials['private_materials']),
      ),
    ].where((group) => group.rows.isNotEmpty).toList(growable: false);
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, '使用素材', 'Used sources'),
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...groups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${group.title} · ${group.rows.length}',
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...group.rows
                      .take(3)
                      .map(
                        (row) => Text(
                          '· ${_sourceTitle(context, row)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.bodyText,
                            fontSize: 13,
                            height: 1.45,
                          ),
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

class _SourceMaterialGroup {
  const _SourceMaterialGroup({required this.title, required this.rows});

  final String title;
  final List<Map<String, dynamic>> rows;
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

String _ruleText(BuildContext context, MemoirConfig item) {
  final levelText = switch (item.triggerMode) {
    'level_interval' => _t(
      context,
      '每升 ${item.levelStep <= 1 ? 1 : item.levelStep} 级',
      'every ${item.levelStep <= 1 ? 1 : item.levelStep} levels',
    ),
    'cycle' => _cycleLabel(context, item.generationCycle),
    'manual' => _t(context, '后台手动', 'manual'),
    _ => _t(context, '每升一级', 'each level'),
  };
  final sourceText = _sourceLabels(context, item).join('、');
  final status = item.canGenerate
      ? (item.triggerMode == 'cycle' || item.triggerMode == 'manual'
            ? _t(context, '，当前可生成', ', ready to generate')
            : (item.targetLevelName.isEmpty
                  ? _t(context, '，当前可生成', ', ready to generate')
                  : _t(
                      context,
                      '，当前可生成：${item.targetLevelName}',
                      ', ready: ${item.targetLevelName}',
                    )))
      : (item.existingMemoirId > 0
            ? _t(context, '，已生成本档回忆录', ', already generated')
            : '');

  return _t(
    context,
    '${item.name}：$levelText 可生成，素材来自 $sourceText$status',
    '${item.name}: $levelText generation, sources: $sourceText$status',
  );
}

String _reasonText(BuildContext context, MemoirConfig item) {
  return switch (item.reason) {
    '当前等级回忆录已生成' || '本周期回忆录已生成' => context.l10n.meMemoirGenerated,
    '可用素材数量未达到配置要求' => _t(
      context,
      '当前周期素材还不够，先去留下更多记录吧',
      'Not enough sources in this period yet.',
    ),
    '当前会员等级未达到生成间隔' => _t(
      context,
      '还没到可生成的等级',
      'This level is not eligible yet.',
    ),
    '未达到生成条件' => _t(context, '暂未达到生成条件', 'Requirements not met yet.'),
    _ => item.reason,
  };
}

List<String> _sourceLabels(BuildContext context, MemoirConfig item) {
  final sourceValues = item.materialSources.isNotEmpty
      ? item.materialSources
      : switch (item.sourceType) {
          'journal' => const ['journal'],
          'task' => const ['task'],
          _ => const [
            'journal',
            'task',
            'material_history',
            'material_collect',
            'private_material',
          ],
        };
  return sourceValues
      .map(
        (value) => switch (value) {
          'task' => _t(context, '任务', 'tasks'),
          'material_history' => _t(context, '学习记录', 'learning history'),
          'material_collect' => _t(context, '收藏素材', 'saved materials'),
          'private_material' => _t(context, '私人素材', 'private materials'),
          _ => _t(context, '日记', 'journals'),
        },
      )
      .toList(growable: false);
}

List<Map<String, dynamic>> _sourceRows(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((row) => row.map((key, item) => MapEntry(key.toString(), item)))
      .toList(growable: false);
}

String _sourceTitle(BuildContext context, Map<String, dynamic> row) {
  final title = (row['title'] ?? '').toString().trim();
  if (title.isNotEmpty) {
    return title;
  }
  final summary = (row['summary'] ?? '').toString().trim();
  final date = (row['entry_date'] ?? row['task_date'] ?? row['viewed_at'] ?? '')
      .toString()
      .trim();
  if (date.isNotEmpty && summary.isNotEmpty) {
    return '$date · $summary';
  }
  if (summary.isNotEmpty) {
    return summary;
  }
  return date.isEmpty ? _t(context, '未命名素材', 'Untitled') : date;
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
    required this.accent,
  });

  factory _MemoirPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _MemoirPalette(
      pageBackground: isDark ? scheme.surface : const Color(0xFFF4F5F9),
      cardBackground: isDark
          ? scheme.surfaceContainerLowest
          : Colors.white,
      softBackground: isDark
          ? scheme.surfaceContainerLow
          : const Color(0xFFF7F7FA),
      primaryText: isDark ? scheme.onSurface : const Color(0xFF303236),
      secondaryText: isDark ? scheme.onSurfaceVariant : const Color(0xFF96999F),
      bodyText: isDark
          ? scheme.onSurface.withValues(alpha: 0.84)
          : const Color(0xFF4A4D55),
      accent: isDark ? const Color(0xFFFFB4A8) : const Color(0xFFFF9585),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color bodyText;
  final Color accent;
}
