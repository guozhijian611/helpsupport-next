import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/providers/app_providers.dart';
import '../../material/application/material_controller.dart';
import '../../material/data/material_models.dart';

class MaterialLibraryScreen extends ConsumerStatefulWidget {
  const MaterialLibraryScreen({
    super.key,
    required this.materialType,
    required this.source,
  });

  final String materialType;
  final MaterialLibrarySource source;

  @override
  ConsumerState<MaterialLibraryScreen> createState() =>
      _MaterialLibraryScreenState();
}

class _MaterialLibraryScreenState extends ConsumerState<MaterialLibraryScreen> {
  final _searchController = TextEditingController();
  String _keyword = '';
  int _categoryId = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.source == MaterialLibrarySource.browse
        ? ref.watch(materialCategoriesProvider(widget.materialType))
        : const AsyncData<List<MaterialCategory>>([]);
    final listQuery = MaterialListQuery(
      materialType: widget.materialType,
      categoryId: _categoryId,
      keyword: _keyword,
    );
    final items = switch (widget.source) {
      MaterialLibrarySource.browse => ref.watch(
        materialListProvider(listQuery),
      ),
      MaterialLibrarySource.collections => ref.watch(
        materialCollectionsProvider(const MaterialHistoryQuery()),
      ),
      MaterialLibrarySource.history => ref.watch(
        materialHistoryProvider(const MaterialHistoryQuery()),
      ),
    };

    final categoryLookup = switch (categories) {
      AsyncData(:final value) => {for (final item in value) item.id: item.name},
      _ => const <int, String>{},
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: Text(_screenTitle(context)),
        centerTitle: true,
        actions: widget.source == MaterialLibrarySource.browse
            ? [
                IconButton(
                  tooltip: _t(context, '我的收藏', 'Collections'),
                  onPressed: () => context.push(
                    '/materials?type=${widget.materialType}&source=collections',
                  ),
                  icon: const Icon(Icons.folder_open_outlined),
                ),
                IconButton(
                  tooltip: _t(context, '浏览历史', 'History'),
                  onPressed: () => context.push(
                    '/materials?type=${widget.materialType}&source=history',
                  ),
                  icon: const Icon(Icons.history_rounded),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refreshCurrent(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              if (widget.source == MaterialLibrarySource.browse) ...[
                _SearchBar(
                  controller: _searchController,
                  onSearch: () =>
                      setState(() => _keyword = _searchController.text.trim()),
                ),
                const SizedBox(height: 14),
                categories.when(
                  data: (values) => _CategoryStrip(
                    categories: values,
                    selectedId: _categoryId,
                    onSelected: (id) => setState(() => _categoryId = id),
                  ),
                  error: (error, _) => _InlineStatus(text: error.toString()),
                  loading: () => const _CategoryStripSkeleton(),
                ),
                const SizedBox(height: 18),
              ] else ...[
                _SourceSummaryBanner(
                  source: widget.source,
                  materialType: widget.materialType,
                ),
                const SizedBox(height: 18),
              ],
              items.when(
                data: (page) {
                  if (page.list.isEmpty) {
                    return _EmptyPanel(
                      title: _emptyTitle(context),
                      subtitle: _emptySubtitle(context),
                    );
                  }
                  if (widget.source == MaterialLibrarySource.history) {
                    return Column(
                      children: [
                        for (final entry
                            in page.list.cast<MaterialHistoryEntry>())
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _HistoryCard(entry: entry),
                          ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (final item in page.list.cast<MaterialItem>())
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _MaterialCard(
                            item: item,
                            categoryName: categoryLookup[item.categoryId] ?? '',
                            isCollectionView:
                                widget.source ==
                                MaterialLibrarySource.collections,
                          ),
                        ),
                    ],
                  );
                },
                error: (error, _) => _EmptyPanel(
                  title: context.l10n.networkUnavailable,
                  subtitle: error.toString(),
                ),
                loading: () => const _LibraryLoadingList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshCurrent() async {
    switch (widget.source) {
      case MaterialLibrarySource.browse:
        ref.invalidate(materialCategoriesProvider(widget.materialType));
        ref.invalidate(
          materialListProvider(
            MaterialListQuery(
              materialType: widget.materialType,
              categoryId: _categoryId,
              keyword: _keyword,
            ),
          ),
        );
        await Future.wait([
          ref.read(materialCategoriesProvider(widget.materialType).future),
          ref.read(
            materialListProvider(
              MaterialListQuery(
                materialType: widget.materialType,
                categoryId: _categoryId,
                keyword: _keyword,
              ),
            ).future,
          ),
        ]);
      case MaterialLibrarySource.collections:
        ref.invalidate(
          materialCollectionsProvider(const MaterialHistoryQuery()),
        );
        await ref.read(
          materialCollectionsProvider(const MaterialHistoryQuery()).future,
        );
      case MaterialLibrarySource.history:
        ref.invalidate(materialHistoryProvider(const MaterialHistoryQuery()));
        await ref.read(
          materialHistoryProvider(const MaterialHistoryQuery()).future,
        );
    }
  }

  String _screenTitle(BuildContext context) {
    return switch (widget.source) {
      MaterialLibrarySource.history => _t(context, '浏览历史', 'History'),
      MaterialLibrarySource.collections => _t(context, '我的收藏', 'Collections'),
      MaterialLibrarySource.browse =>
        widget.materialType == 'entertainment'
            ? _t(context, '娱乐', 'Entertainment')
            : _t(context, '教育素材', 'Learning'),
    };
  }

  String _emptyTitle(BuildContext context) {
    return switch (widget.source) {
      MaterialLibrarySource.history => _t(context, '还没有浏览历史', 'No history yet'),
      MaterialLibrarySource.collections => _t(
        context,
        '还没有收藏内容',
        'No saved materials yet',
      ),
      MaterialLibrarySource.browse => _t(context, '暂无素材', 'No materials yet'),
    };
  }

  String _emptySubtitle(BuildContext context) {
    return switch (widget.source) {
      MaterialLibrarySource.history => _t(
        context,
        '阅读过的素材会出现在这里，方便继续学习。',
        'Materials you open will appear here for quick return.',
      ),
      MaterialLibrarySource.collections => _t(
        context,
        '收藏后可以在这里集中查看高价值内容。',
        'Saved materials will gather here for quick access.',
      ),
      MaterialLibrarySource.browse => _t(
        context,
        '试试切换分类或关键词，查看当前已发布的真实内容。',
        'Try another category or keyword to explore real published content.',
      ),
    };
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE6E8EE)),
            ),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: _t(context, '输入关键词', 'Search by keyword'),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        TextButton(onPressed: onSearch, child: Text(_t(context, '搜索', 'Go'))),
      ],
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<MaterialCategory> categories;
  final int selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryChip(
            label: _t(context, '全部', 'All'),
            selected: selectedId == 0,
            onTap: () => onSelected(0),
          ),
          for (final item in categories) ...[
            const SizedBox(width: 10),
            _CategoryChip(
              label: item.name,
              selected: selectedId == item.id,
              onTap: () => onSelected(item.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6EEFF) : Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF5A81DA) : const Color(0xFF343437),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MaterialCard extends ConsumerWidget {
  const _MaterialCard({
    required this.item,
    required this.categoryName,
    required this.isCollectionView,
  });

  final MaterialItem item;
  final String categoryName;
  final bool isCollectionView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);
    final coverUrl = apiClient.resolveUrl(item.coverUrl);
    final chips = [
      if (categoryName.isNotEmpty) categoryName,
      if (item.mediaType.isNotEmpty) _mediaLabel(context, item.mediaType),
      ...item.tags.take(2),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.push('/materials/detail/${item.id}'),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _MediaIcon(mediaType: item.mediaType),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF303236),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (isCollectionView)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1DE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _t(context, '已收藏', 'Saved'),
                              style: const TextStyle(
                                color: Color(0xFFFFAE4D),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.summary.isNotEmpty
                          ? item.summary
                          : _t(
                              context,
                              '点击查看完整内容与互动评论。',
                              'Tap to open the full content and comments.',
                            ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5E6470),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final chip in chips)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F5F9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '# $chip',
                              style: const TextStyle(
                                color: Color(0xFF4A4D55),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _StatInfo(
                          icon: Icons.thumb_up_alt_outlined,
                          value: item.likeCount,
                        ),
                        const SizedBox(width: 14),
                        _StatInfo(
                          icon: Icons.bookmark_border_rounded,
                          value: item.collectCount,
                        ),
                        const SizedBox(width: 14),
                        _StatInfo(
                          icon: Icons.chat_bubble_outline_rounded,
                          value: item.commentCount,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 118,
                height: 118,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const _MaterialThumbShell(),
                        )
                      : const _MaterialThumbShell(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final MaterialHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: entry.contentId > 0
            ? () => context.push('/materials/detail/${entry.contentId}')
            : null,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              _MediaIcon(
                mediaType: entry.contentType == 'material'
                    ? 'article'
                    : entry.contentType,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF303236),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.authorName.isNotEmpty
                          ? entry.authorName
                          : _t(
                              context,
                              '继续上次阅读',
                              'Continue where you left off',
                            ),
                      style: const TextStyle(
                        color: Color(0xFF7D828A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.viewedAt,
                      style: const TextStyle(
                        color: Color(0xFF96999F),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB0B3BA),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaIcon extends StatelessWidget {
  const _MediaIcon({required this.mediaType});

  final String mediaType;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (mediaType) {
      'video' => (Icons.play_circle_fill_rounded, const Color(0xFF6A93D5)),
      'audio' => (Icons.music_note_rounded, const Color(0xFFF8B048)),
      'pdf' || 'epub' => (Icons.menu_book_rounded, const Color(0xFF60B2A5)),
      'link' => (Icons.open_in_new_rounded, const Color(0xFF986FF5)),
      _ => (Icons.auto_stories_rounded, const Color(0xFFF29C88)),
    };

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _MaterialThumbShell extends StatelessWidget {
  const _MaterialThumbShell();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF4EF), Color(0xFFF5F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_stories_rounded,
          color: Color(0xFFD89A8C),
          size: 42,
        ),
      ),
    );
  }
}

class _StatInfo extends StatelessWidget {
  const _StatInfo({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: const Color(0xFF9CA1AA)),
        const SizedBox(width: 6),
        Text(
          '$value',
          style: const TextStyle(
            color: Color(0xFF8B9098),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SourceSummaryBanner extends StatelessWidget {
  const _SourceSummaryBanner({
    required this.source,
    required this.materialType,
  });

  final MaterialLibrarySource source;
  final String materialType;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, colors) = switch (source) {
      MaterialLibrarySource.collections => (
        _t(context, '你收藏的高价值内容', 'Your saved high-value content'),
        _t(
          context,
          '把想反复阅读的内容集中保存，方便长期复盘。',
          'Keep the materials worth revisiting in one place.',
        ),
        const [Color(0xFFFFC56F), Color(0xFFFFAE4D)],
      ),
      MaterialLibrarySource.history => (
        _t(context, '最近浏览记录', 'Recent reading trail'),
        _t(
          context,
          '这里保留你最近打开过的素材，帮助你接上进度。',
          'Return to the materials you recently opened and continue.',
        ),
        const [Color(0xFF8EA8F8), Color(0xFF6D8DE7)],
      ),
      MaterialLibrarySource.browse => (
        materialType == 'entertainment'
            ? _t(context, '恢复也需要轻松入口', 'Recovery needs lighter moments')
            : _t(context, '稳定学习，循序前进', 'Steady learning, step by step'),
        materialType == 'entertainment'
            ? _t(
                context,
                '音乐、视频和轻内容能帮你从高压中切换出来。',
                'Music, videos, and lighter content can create breathing room.',
              )
            : _t(
                context,
                '从基础认知到复发预防，把有用的内容真正看进去。',
                'Move from fundamentals to relapse prevention with useful material.',
              ),
        const [Color(0xFFB695F6), Color(0xFFA07CEE)],
      ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: colors),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFF6F5FF),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF7D828A))),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: Color(0xFFD0D3DA),
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7D828A), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _CategoryStripSkeleton extends StatelessWidget {
  const _CategoryStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        4,
        (index) => Container(
          width: 74,
          height: 40,
          margin: EdgeInsets.only(right: index == 3 ? 0 : 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _LibraryLoadingList extends StatelessWidget {
  const _LibraryLoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 176,
          margin: EdgeInsets.only(bottom: index == 2 ? 0 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}

String _mediaLabel(BuildContext context, String mediaType) {
  return switch (mediaType) {
    'video' => _t(context, '视频', 'Video'),
    'audio' => _t(context, '音频', 'Audio'),
    'pdf' => 'PDF',
    'epub' => 'EPUB',
    'link' => _t(context, '链接', 'Link'),
    _ => _t(context, '文章', 'Article'),
  };
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
