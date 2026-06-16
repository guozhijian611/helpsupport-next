import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
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
  final Set<int> _submittingCollectionIds = <int>{};
  String _keyword = '';
  int _categoryId = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialLibraryPalette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final categoriesQuery = MaterialCategoriesQuery(
      type: widget.materialType,
      locale: locale,
    );
    final categories = widget.source == MaterialLibrarySource.browse
        ? ref.watch(materialCategoriesProvider(categoriesQuery))
        : const AsyncData<List<MaterialCategory>>([]);
    final listQuery = MaterialListQuery(
      materialType: widget.materialType,
      categoryId: _categoryId,
      keyword: _keyword,
      locale: locale,
    );
    final collectionQuery = MaterialListQuery(
      materialType: '',
      categoryId: 0,
      keyword: '',
      locale: locale,
    );
    final items = switch (widget.source) {
      MaterialLibrarySource.browse => ref.watch(
        materialListProvider(listQuery),
      ),
      MaterialLibrarySource.collections => ref.watch(
        materialCollectionsProvider(collectionQuery),
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
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: Text(_screenTitle(context)),
        centerTitle: true,
        backgroundColor: palette.appBarBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: widget.source == MaterialLibrarySource.browse
            ? [
                if (widget.materialType == 'private')
                  IconButton(
                    tooltip: _t(context, '上传私人素材', 'Upload private material'),
                    onPressed: () => context.push('/materials/private/upload'),
                    icon: const Icon(Icons.add_rounded),
                  )
                else if (widget.materialType == 'entertainment')
                  const SizedBox(width: 8)
                else ...[
                  TextButton(
                    onPressed: () => context.push('/materials?type=private'),
                    child: Text(
                      _t(context, '私', 'Me'),
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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
                ],
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
                  data: (values) {
                    final showAll = widget.materialType != 'entertainment';
                    if (!showAll) {
                      _ensureEntertainmentCategory(values);
                    }
                    return _CategoryStrip(
                      categories: values,
                      selectedId: _categoryId,
                      showAll: showAll,
                      onSelected: (id) => setState(() => _categoryId = id),
                    );
                  },
                  error: (error, _) => _InlineStatus(text: error.toString()),
                  loading: () => const _CategoryStripSkeleton(),
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
                    return _HistoryTimeline(
                      entries: page.list.cast<MaterialHistoryEntry>(),
                    );
                  }
                  final list = page.list.cast<MaterialItem>();
                  if (widget.source == MaterialLibrarySource.browse &&
                      widget.materialType == 'entertainment') {
                    return _EntertainmentGrid(
                      items: list,
                      categoryLookup: categoryLookup,
                    );
                  }
                  return Column(
                    children: [
                      for (final item in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child:
                              widget.source == MaterialLibrarySource.collections
                              ? Dismissible(
                                  key: ValueKey('collection-${item.id}'),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) =>
                                      _removeCollection(context, item),
                                  background:
                                      const _CollectionDismissBackground(),
                                  child: _MaterialCard(
                                    item: item,
                                    categoryName:
                                        categoryLookup[item.categoryId] ?? '',
                                    isCollectionView: true,
                                    dismissing: _submittingCollectionIds
                                        .contains(item.id),
                                  ),
                                )
                              : _MaterialCard(
                                  item: item,
                                  categoryName:
                                      categoryLookup[item.categoryId] ?? '',
                                  isCollectionView: false,
                                  dismissing: false,
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

  void _ensureEntertainmentCategory(List<MaterialCategory> categories) {
    if (categories.isEmpty ||
        categories.any((category) => category.id == _categoryId)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || categories.isEmpty) {
        return;
      }
      final nextCategoryId = categories.first.id;
      if (_categoryId != nextCategoryId) {
        setState(() => _categoryId = nextCategoryId);
      }
    });
  }

  Future<void> _refreshCurrent() async {
    switch (widget.source) {
      case MaterialLibrarySource.browse:
        final locale = Localizations.localeOf(context).toLanguageTag();
        final categoriesQuery = MaterialCategoriesQuery(
          type: widget.materialType,
          locale: locale,
        );
        final listQuery = MaterialListQuery(
          materialType: widget.materialType,
          categoryId: _categoryId,
          keyword: _keyword,
          locale: locale,
        );
        ref.invalidate(materialCategoriesProvider(categoriesQuery));
        ref.invalidate(materialListProvider(listQuery));
        await Future.wait([
          ref.read(materialCategoriesProvider(categoriesQuery).future),
          ref.read(materialListProvider(listQuery).future),
        ]);
      case MaterialLibrarySource.collections:
        final locale = Localizations.localeOf(context).toLanguageTag();
        final query = MaterialListQuery(
          materialType: '',
          categoryId: 0,
          keyword: '',
          locale: locale,
        );
        ref.invalidate(materialCollectionsProvider(query));
        await ref.read(materialCollectionsProvider(query).future);
      case MaterialLibrarySource.history:
        ref.invalidate(materialHistoryProvider(const MaterialHistoryQuery()));
        await ref.read(
          materialHistoryProvider(const MaterialHistoryQuery()).future,
        );
    }
  }

  String _screenTitle(BuildContext context) {
    return switch (widget.source) {
      MaterialLibrarySource.history => _t(context, '历史记录', 'History'),
      MaterialLibrarySource.collections => _t(context, '我的收藏', 'Collections'),
      MaterialLibrarySource.browse =>
        widget.materialType == 'private'
            ? _t(context, '私人素材', 'Private Materials')
            : widget.materialType == 'entertainment'
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
      MaterialLibrarySource.browse =>
        widget.materialType == 'private'
            ? _t(context, '还没有私人素材', 'No private materials yet')
            : _t(context, '暂无素材', 'No materials yet'),
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
      MaterialLibrarySource.browse =>
        widget.materialType == 'private'
            ? _t(
                context,
                '上传后的素材只会出现在你的账号中。',
                'Uploaded materials stay visible only to your account.',
              )
            : _t(
                context,
                '试试切换分类或关键词，查看当前已发布的真实内容。',
                'Try another category or keyword to explore real published content.',
              ),
    };
  }

  Future<bool> _removeCollection(
    BuildContext context,
    MaterialItem item,
  ) async {
    if (_submittingCollectionIds.contains(item.id)) {
      return false;
    }
    setState(() => _submittingCollectionIds.add(item.id));
    try {
      final isCollected = await ref
          .read(materialRepositoryProvider)
          .toggleCollect(item.id);
      final locale = Localizations.localeOf(context).toLanguageTag();
      ref.invalidate(
        materialCollectionsProvider(
          MaterialListQuery(
            materialType: '',
            categoryId: 0,
            keyword: '',
            locale: locale,
          ),
        ),
      );
      ref.invalidate(
        materialDetailProvider(
          MaterialDetailQuery(id: item.id, locale: locale),
        ),
      );
      if (context.mounted) {
        context.showCenteredNotice(
          isCollected
              ? _t(context, '已恢复收藏状态', 'Collection restored')
              : _t(context, '已取消收藏', 'Removed from collections'),
        );
      }
      return !isCollected;
    } on Object catch (error) {
      if (context.mounted) {
        context.showCenteredNotice(error.toString());
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _submittingCollectionIds.remove(item.id));
      }
    }
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialLibraryPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.outline),
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
    required this.showAll,
    required this.onSelected,
  });

  final List<MaterialCategory> categories;
  final int selectedId;
  final bool showAll;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (showAll)
        _CategoryChip(
          label: _t(context, '全部', 'All'),
          selected: selectedId == 0,
          onTap: () => onSelected(0),
        ),
      for (final item in categories) ...[
        if (showAll || item != categories.first) const SizedBox(width: 10),
        _CategoryChip(
          label: item.name,
          selected: selectedId == item.id,
          onTap: () => onSelected(item.id),
        ),
      ],
    ];
    return SizedBox(
      height: 42,
      child: ListView(scrollDirection: Axis.horizontal, children: chips),
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
    final palette = _MaterialLibraryPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? palette.selectedChipBackground
              : palette.cardBackground,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? palette.selectedChipText : palette.primaryText,
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
    required this.dismissing,
  });

  final MaterialItem item;
  final String categoryName;
  final bool isCollectionView;
  final bool dismissing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MaterialLibraryPalette.of(context);
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
            color: palette.cardBackground,
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
                            style: TextStyle(
                              color: palette.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
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
                      style: TextStyle(color: palette.bodyText, height: 1.55),
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
                              color: palette.tagBackground,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '# $chip',
                              style: TextStyle(
                                color: palette.bodyText,
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
                          icon: isCollectionView
                              ? Icons.star_rounded
                              : Icons.bookmark_border_rounded,
                          value: item.collectCount,
                          color: isCollectionView
                              ? const Color(0xFFFFB648)
                              : const Color(0xFF9CA1AA),
                          valueColor: isCollectionView
                              ? const Color(0xFFFFB648)
                              : const Color(0xFF8B9098),
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
                child: Stack(
                  children: [
                    Positioned.fill(
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
                    if (_isPlayableMedia(item.mediaType))
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                      ),
                    if (dismissing)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.68),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntertainmentGrid extends StatelessWidget {
  const _EntertainmentGrid({required this.items, required this.categoryLookup});

  final List<MaterialItem> items;
  final Map<int, String> categoryLookup;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 18,
        mainAxisSpacing: 22,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _EntertainmentGridCard(
          item: item,
          categoryName: categoryLookup[item.categoryId] ?? '',
        );
      },
    );
  }
}

class _EntertainmentGridCard extends ConsumerWidget {
  const _EntertainmentGridCard({
    required this.item,
    required this.categoryName,
  });

  final MaterialItem item;
  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MaterialLibraryPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final coverUrl = apiClient.resolveUrl(item.coverUrl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/materials/detail/${item.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverUrl.isNotEmpty
                        ? Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const _MaterialThumbShell(),
                          )
                        : const _MaterialThumbShell(),
                    if (_isPlayableMedia(item.mediaType))
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _EntertainmentMediaBadge(
                        label: _mediaLabel(context, item.mediaType),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              categoryName.isNotEmpty
                  ? categoryName
                  : _t(context, '官方发布', 'Official'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.secondaryText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntertainmentMediaBadge extends StatelessWidget {
  const _EntertainmentMediaBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CollectionDismissBackground extends StatelessWidget {
  const _CollectionDismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFC15C),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_outline_rounded,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              _t(context, '取消收藏', 'Remove'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.entries});

  final List<MaterialHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialLibraryPalette.of(context);
    final sections = <MapEntry<String, List<MaterialHistoryEntry>>>[];
    for (final entry in entries) {
      final label = _historyDateLabel(entry.viewedAt);
      if (sections.isEmpty || sections.last.key != label) {
        sections.add(MapEntry(label, <MaterialHistoryEntry>[entry]));
      } else {
        sections.last.value.add(entry);
      }
    }

    return Column(
      children: [
        for (final section in sections) ...[
          _HistorySectionHeader(label: section.key),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                for (var index = 0; index < section.value.length; index += 1)
                  _HistoryRow(
                    entry: section.value[index],
                    showDivider: index != section.value.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        const _HistoryEndHint(),
      ],
    );
  }
}

class _HistorySectionHeader extends StatelessWidget {
  const _HistorySectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialLibraryPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: palette.sectionHeaderBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.secondaryText,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.showDivider});

  final MaterialHistoryEntry entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialLibraryPalette.of(context);
    final onTap = entry.contentId > 0
        ? () => context.push('/materials/detail/${entry.contentId}')
        : entry.route.trim().isNotEmpty
        ? () => context.push(entry.route)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: palette.outline, width: 1))
                : null,
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
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                entry.progress > 0
                    ? '${entry.progress.clamp(0, 100).toStringAsFixed(0)}%'
                    : entry.authorName.trim().isEmpty
                    ? _t(context, '作者名', 'Author')
                    : entry.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryEndHint extends StatelessWidget {
  const _HistoryEndHint();

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialLibraryPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: palette.outline, indent: 26, endIndent: 10),
          ),
          Text(
            _t(context, '已显示所有记录', 'All records shown'),
            style: TextStyle(
              color: palette.secondaryText.withValues(alpha: 0.72),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Divider(color: palette.outline, indent: 10, endIndent: 26),
          ),
        ],
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
      'video' ||
      'mp4' ||
      'mov' => (Icons.play_circle_fill_rounded, const Color(0xFF6A93D5)),
      'audio' || 'mp3' => (Icons.music_note_rounded, const Color(0xFFF8B048)),
      'txt' ||
      'pdf' ||
      'epub' => (Icons.menu_book_rounded, const Color(0xFF60B2A5)),
      'link' => (Icons.sports_esports_rounded, const Color(0xFF986FF5)),
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
    final palette = _MaterialLibraryPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.thumbGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_stories_rounded,
          color: palette.thumbIcon,
          size: 42,
        ),
      ),
    );
  }
}

class _StatInfo extends StatelessWidget {
  const _StatInfo({
    required this.icon,
    required this.value,
    this.color = const Color(0xFF9CA1AA),
    this.valueColor = const Color(0xFF8B9098),
  });

  final IconData icon;
  final int value;
  final Color color;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 6),
        Text(
          '$value',
          style: TextStyle(color: valueColor, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialLibraryPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(text, style: TextStyle(color: palette.secondaryText)),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialLibraryPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_rounded,
            color: palette.secondaryText.withValues(alpha: 0.58),
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

class _CategoryStripSkeleton extends StatelessWidget {
  const _CategoryStripSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialLibraryPalette.of(context);
    return Row(
      children: List.generate(
        4,
        (index) => Container(
          width: 74,
          height: 40,
          margin: EdgeInsets.only(right: index == 3 ? 0 : 10),
          decoration: BoxDecoration(
            color: palette.cardBackground,
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
    final palette = _MaterialLibraryPalette.of(context);
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 176,
          margin: EdgeInsets.only(bottom: index == 2 ? 0 : 14),
          decoration: BoxDecoration(
            color: palette.cardBackground,
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
    'txt' => 'TXT',
    'pdf' => 'PDF',
    'epub' => 'EPUB',
    'mp4' => 'MP4',
    'mov' => 'MOV',
    'mp3' => 'MP3',
    'link' => _t(context, '游戏', 'Game'),
    _ => _t(context, '文章', 'Article'),
  };
}

bool _isPlayableMedia(String mediaType) {
  return mediaType == 'video' || mediaType == 'mp4' || mediaType == 'mov';
}

String _historyDateLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '--';
  }
  final normalized = trimmed.replaceAll('/', '-');
  if (normalized.length >= 10) {
    return normalized.substring(0, 10);
  }
  return normalized;
}

class _MaterialLibraryPalette {
  const _MaterialLibraryPalette({
    required this.pageBackground,
    required this.appBarBackground,
    required this.cardBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.bodyText,
    required this.outline,
    required this.tagBackground,
    required this.sectionHeaderBackground,
    required this.selectedChipBackground,
    required this.selectedChipText,
    required this.thumbGradient,
    required this.thumbIcon,
  });

  static _MaterialLibraryPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _MaterialLibraryPalette(
      pageBackground: scheme.surface,
      appBarBackground: isDark ? scheme.surface : scheme.surfaceContainerLowest,
      cardBackground: scheme.surfaceContainerLowest,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      bodyText: isDark
          ? scheme.onSurface.withValues(alpha: 0.82)
          : const Color(0xFF5E6470),
      outline: scheme.outlineVariant,
      tagBackground: scheme.surfaceContainerLow,
      sectionHeaderBackground: scheme.surfaceContainerHigh,
      selectedChipBackground: isDark
          ? scheme.primaryContainer
          : const Color(0xFFE6EEFF),
      selectedChipText: isDark
          ? scheme.onPrimaryContainer
          : const Color(0xFF5A81DA),
      thumbGradient: isDark
          ? const [Color(0xFF2E3440), Color(0xFF233047)]
          : const [Color(0xFFFFF4EF), Color(0xFFF5F7FF)],
      thumbIcon: isDark ? scheme.primary : const Color(0xFFD89A8C),
    );
  }

  final Color pageBackground;
  final Color appBarBackground;
  final Color cardBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color bodyText;
  final Color outline;
  final Color tagBackground;
  final Color sectionHeaderBackground;
  final Color selectedChipBackground;
  final Color selectedChipText;
  final List<Color> thumbGradient;
  final Color thumbIcon;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
