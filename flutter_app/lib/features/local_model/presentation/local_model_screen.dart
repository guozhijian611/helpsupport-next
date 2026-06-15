import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/local_model_controller.dart';
import '../data/local_model_models.dart';

class LocalModelScreen extends ConsumerStatefulWidget {
  const LocalModelScreen({
    super.key,
    this.preferredChatMode = '',
    this.preferredTitle = '',
  });

  final String preferredChatMode;
  final String preferredTitle;

  @override
  ConsumerState<LocalModelScreen> createState() => _LocalModelScreenState();
}

class _LocalModelScreenState extends ConsumerState<LocalModelScreen> {
  final _searchController = TextEditingController();
  _ModelFilter _filter = _ModelFilter.all;
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _LocalModelScreenPalette.of(context);
    final catalog = ref.watch(localModelCatalogProvider);
    final downloadStates = ref.watch(localModelDownloadControllerProvider);
    final states = downloadStates.hasValue
        ? downloadStates.value ?? const <int, LocalModelDownloadState>{}
        : const <int, LocalModelDownloadState>{};

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(context.l10n.localModelTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: catalog.when(
          data: (items) {
            final filtered = _applyFilter(items, states);
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(localModelCatalogProvider);
                ref.invalidate(localModelDownloadControllerProvider);
                await Future.wait([
                  ref.read(localModelCatalogProvider.future),
                  ref.read(localModelDownloadControllerProvider.future),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  if (widget.preferredChatMode.trim().isNotEmpty) ...[
                    _EntryBanner(
                      chatMode: widget.preferredChatMode,
                      title: widget.preferredTitle,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _SearchBar(
                    controller: _searchController,
                    onSearch: () => setState(
                      () => _keyword = _searchController.text.trim(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FilterTabs(
                    value: _filter,
                    onChanged: (next) => setState(() => _filter = next),
                  ),
                  const SizedBox(height: 18),
                  if (filtered.isEmpty)
                    _EmptyState(
                      message: _t(
                        context,
                        '当前筛选条件下没有模型，试试切换分类或关键词。',
                        'No models match this filter. Try another keyword or tab.',
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.58,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final state =
                            states[item.id] ??
                            const LocalModelDownloadState.notDownloaded();
                        return _ModelCard(
                          item: item,
                          state: state,
                          preferredChatMode: widget.preferredChatMode,
                          preferredTitle: widget.preferredTitle,
                        );
                      },
                    ),
                ],
              ),
            );
          },
          error: (error, stackTrace) => _ErrorState(
            onRetry: () {
              ref.invalidate(localModelCatalogProvider);
              ref.invalidate(localModelDownloadControllerProvider);
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  List<LocalModelItem> _applyFilter(
    List<LocalModelItem> items,
    Map<int, LocalModelDownloadState> states,
  ) {
    final keyword = _keyword.trim().toLowerCase();
    return items
        .where((item) {
          final state =
              states[item.id] ?? const LocalModelDownloadState.notDownloaded();
          final matchesTab = switch (_filter) {
            _ModelFilter.all => true,
            _ModelFilter.downloaded => state.isReady,
            _ModelFilter.notDownloaded => !state.isReady,
          };
          if (!matchesTab) {
            return false;
          }
          if (keyword.isEmpty) {
            return true;
          }
          final text = [
            item.name,
            item.code,
            item.provider,
            item.modelFamily,
            item.intro,
          ].join(' ').toLowerCase();
          return text.contains(keyword);
        })
        .toList(growable: false);
  }
}

enum _ModelFilter { all, downloaded, notDownloaded }

class _EntryBanner extends StatelessWidget {
  const _EntryBanner({required this.chatMode, required this.title});

  final String chatMode;
  final String title;

  @override
  Widget build(BuildContext context) {
    final (headline, subtitle, colors, icon) = switch (chatMode) {
      'doctor' => (
        _t(context, '已切换到本地心理医生', 'Local AI doctor ready'),
        _t(
          context,
          '选择一个已下载模型后，将直接进入当前对话模式。',
          'Pick a downloaded model and jump straight into this conversation mode.',
        ),
        const [Color(0xFF74B3F6), Color(0xFF5A95E0)],
        Icons.smart_toy_rounded,
      ),
      'patient' => (
        _t(context, '已切换到本地模拟病人', 'Local AI patient ready'),
        _t(
          context,
          '更适合离线场景下的角色演练与沟通练习。',
          'Best for offline role-play and guided communication practice.',
        ),
        const [Color(0xFFFFC46D), Color(0xFFFFAB48)],
        Icons.healing_rounded,
      ),
      _ => (
        _t(context, '已切换到本地心理陪伴', 'Local AI companion ready'),
        _t(
          context,
          '使用本地模型继续稳定、私密的支持性对话。',
          'Continue private and steady support conversations on-device.',
        ),
        const [Color(0xFFF4A798), Color(0xFFE88E84)],
        Icons.favorite_border_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: colors),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isNotEmpty ? title : headline,
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
                    color: Color(0xFFFFF7F4),
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, size: 44, color: Colors.white),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final palette = _LocalModelScreenPalette.of(context);
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
                hintStyle: TextStyle(color: palette.secondaryText),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: palette.secondaryText,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(onPressed: onSearch, child: Text(_t(context, '搜索', 'Go'))),
      ],
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.value, required this.onChanged});

  final _ModelFilter value;
  final ValueChanged<_ModelFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _LocalModelScreenPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final item in _ModelFilter.values)
            Expanded(
              child: _FilterTab(
                label: _label(context, item),
                selected: value == item,
                onTap: () => onChanged(item),
              ),
            ),
        ],
      ),
    );
  }

  String _label(BuildContext context, _ModelFilter value) {
    return switch (value) {
      _ModelFilter.all => _t(context, '全部', 'All'),
      _ModelFilter.downloaded => _t(context, '已下载', 'Downloaded'),
      _ModelFilter.notDownloaded => _t(context, '未下载', 'Not downloaded'),
    };
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _LocalModelScreenPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF5A81DA) : palette.primaryText,
              fontSize: 16,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModelCard extends ConsumerWidget {
  const _ModelCard({
    required this.item,
    required this.state,
    required this.preferredChatMode,
    required this.preferredTitle,
  });

  final LocalModelItem item;
  final LocalModelDownloadState state;
  final String preferredChatMode;
  final String preferredTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenPalette = _LocalModelScreenPalette.of(context);
    final palette = _paletteFor(item.id);
    final title = item.name.isNotEmpty ? item.name : item.code;
    final statusLabel = switch (state.status) {
      LocalModelDownloadStatus.ready => _t(context, '已下载', 'Downloaded'),
      LocalModelDownloadStatus.downloading =>
        state.progress > 0
            ? '${_t(context, '下载中', 'Downloading')} ${(state.progress * 100).clamp(1, 99).round()}%'
            : _t(context, '下载中', 'Downloading'),
      LocalModelDownloadStatus.verifying => _t(context, '校验中', 'Verifying'),
      LocalModelDownloadStatus.failed => _t(context, '重试下载', 'Retry'),
      LocalModelDownloadStatus.notDownloaded => _t(context, '下载', 'Download'),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: state.isReady ? () => _openLocalChat(context) : null,
        child: Ink(
          decoration: BoxDecoration(
            color: screenPalette.cardBackground,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    gradient: LinearGradient(colors: palette.$1),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 18,
                        right: 18,
                        child: state.isReady
                            ? _SmallAction(
                                icon: Icons.delete_outline_rounded,
                                onTap: () => _delete(context, ref),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: palette.$2.withValues(
                                alpha: 0.24,
                              ),
                              child: Icon(
                                palette.$3,
                                size: 42,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              title.isNotEmpty
                                  ? title.substring(0, 1).toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: screenPalette.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _modelMeta(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: screenPalette.secondaryText,
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BottomAction(
                      label: statusLabel,
                      progress: state.status == LocalModelDownloadStatus.ready
                          ? 1
                          : state.progress,
                      isBusy: state.isBusy,
                      isReady: state.isReady,
                      color: palette.$2,
                      onTap: state.isBusy
                          ? null
                          : () => state.isReady
                                ? _openLocalChat(context)
                                : _download(context, ref),
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

  void _openLocalChat(BuildContext context) {
    context.push(
      Uri(
        path: '/local-model/chat/${item.id}',
        queryParameters: {
          'mode': preferredChatMode.isNotEmpty
              ? preferredChatMode
              : 'companion',
          'title': preferredTitle.isNotEmpty
              ? preferredTitle
              : (item.name.isEmpty ? item.code : item.name),
        },
      ).toString(),
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(localModelDownloadControllerProvider.notifier)
          .download(item);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(localModelDownloadControllerProvider.notifier)
          .delete(item);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.label,
    required this.progress,
    required this.isBusy,
    required this.isReady,
    required this.color,
    required this.onTap,
  });

  final String label;
  final double progress;
  final bool isBusy;
  final bool isReady;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.fromLTRB(
          18,
          isBusy ? 10 : 12,
          18,
          isBusy ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isReady ? const Color(0xFF58A45A) : color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: isBusy
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress > 0 && progress < 1
                          ? progress.clamp(0.0, 1.0).toDouble()
                          : null,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.26),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = _LocalModelScreenPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.secondaryText, height: 1.5),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.networkUnavailable),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}

(List<Color>, Color, IconData) _paletteFor(int seed) {
  return switch (seed % 4) {
    0 => (
      const [Color(0xFFF3A391), Color(0xFFE78979)],
      const Color(0xFFE78979),
      Icons.favorite_border_rounded,
    ),
    1 => (
      const [Color(0xFF729AE0), Color(0xFF5A83D3)],
      const Color(0xFF5A83D3),
      Icons.psychology_alt_outlined,
    ),
    2 => (
      const [Color(0xFF9D89F5), Color(0xFF8B74EC)],
      const Color(0xFF8B74EC),
      Icons.self_improvement_rounded,
    ),
    _ => (
      const [Color(0xFFFFC56C), Color(0xFFFFB04B)],
      const Color(0xFFFFB04B),
      Icons.bolt_rounded,
    ),
  };
}

String _modelMeta(LocalModelItem item) {
  return [
    if (item.provider.isNotEmpty) item.provider,
    if (item.modelFamily.isNotEmpty) item.modelFamily,
    if (item.quantization.isNotEmpty) item.quantization,
    if (item.fileSize > 0) _formatBytes(item.fileSize),
  ].join(' / ');
}

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  return '${value.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _LocalModelScreenPalette {
  const _LocalModelScreenPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.outline,
  });

  factory _LocalModelScreenPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _LocalModelScreenPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      outline: scheme.outlineVariant,
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color outline;
}
