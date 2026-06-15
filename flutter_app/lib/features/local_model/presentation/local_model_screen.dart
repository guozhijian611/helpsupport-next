import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/local_model_controller.dart';
import '../data/local_model_models.dart';

class LocalModelScreen extends ConsumerWidget {
  const LocalModelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(localModelCatalogProvider);
    final downloadStates = ref.watch(localModelDownloadControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.localModelTitle)),
      body: SafeArea(
        child: catalog.when(
          data: (items) => items.isEmpty
              ? _EmptyState(message: context.l10n.localModelSubtitle)
              : _CatalogList(
                  items: items,
                  states: downloadStates.hasValue
                      ? downloadStates.value ??
                            const <int, LocalModelDownloadState>{}
                      : const <int, LocalModelDownloadState>{},
                ),
          error: (error, stackTrace) => _ErrorState(
            onRetry: () => ref.invalidate(localModelCatalogProvider),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _CatalogList extends ConsumerWidget {
  const _CatalogList({required this.items, required this.states});

  final List<LocalModelItem> items;
  final Map<int, LocalModelDownloadState> states;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final state =
            states[item.id] ?? const LocalModelDownloadState.notDownloaded();
        return _ModelCard(item: item, state: state);
      },
    );
  }
}

class _ModelCard extends ConsumerWidget {
  const _ModelCard({required this.item, required this.state});

  final LocalModelItem item;
  final LocalModelDownloadState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final statusStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: state.status == LocalModelDownloadStatus.failed
          ? scheme.error
          : scheme.onSurfaceVariant,
    );

    return Card(
      child: ListTile(
        leading: const Icon(Icons.memory_outlined),
        title: Text(item.name.isEmpty ? item.code : item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_modelMeta(item)),
            if (item.intro.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.intro, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            Text(_statusText(context, state), style: statusStyle),
          ],
        ),
        trailing: _DownloadAction(item: item, state: state),
      ),
    );
  }
}

class _DownloadAction extends ConsumerWidget {
  const _DownloadAction({required this.item, required this.state});

  final LocalModelItem item;
  final LocalModelDownloadState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (state.status) {
      LocalModelDownloadStatus.downloading => SizedBox.square(
        dimension: 32,
        child: CircularProgressIndicator(
          value: state.progress > 0 ? state.progress : null,
          strokeWidth: 3,
        ),
      ),
      LocalModelDownloadStatus.verifying => const SizedBox.square(
        dimension: 32,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
      LocalModelDownloadStatus.ready => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            tooltip: context.l10n.localChat,
            onPressed: () => _openLocalChat(context),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            tooltip: context.l10n.deleteModel,
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      LocalModelDownloadStatus.failed ||
      LocalModelDownloadStatus.notDownloaded => IconButton.filledTonal(
        tooltip: context.l10n.downloadModel,
        onPressed: () => _download(context, ref),
        icon: const Icon(Icons.download_outlined),
      ),
    };
  }

  void _openLocalChat(BuildContext context) {
    context.push(
      Uri(
        path: '/local-model/chat/${item.id}',
        queryParameters: {
          'mode': 'companion',
          'title': item.name.isEmpty ? item.code : item.name,
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

String _modelMeta(LocalModelItem item) {
  return [
    if (item.provider.isNotEmpty) item.provider,
    if (item.modelFamily.isNotEmpty) item.modelFamily,
    if (item.quantization.isNotEmpty) item.quantization,
    if (item.minMemoryMb > 0) '${item.minMemoryMb} MB',
    if (item.fileSize > 0) _formatBytes(item.fileSize),
  ].join(' / ');
}

String _statusText(BuildContext context, LocalModelDownloadState state) {
  return switch (state.status) {
    LocalModelDownloadStatus.notDownloaded => context.l10n.modelNotDownloaded,
    LocalModelDownloadStatus.downloading =>
      '${context.l10n.modelDownloading} ${(state.progress * 100).round()}%',
    LocalModelDownloadStatus.verifying => context.l10n.modelVerifying,
    LocalModelDownloadStatus.ready => context.l10n.modelReady,
    LocalModelDownloadStatus.failed =>
      '${context.l10n.modelDownloadFailed}: ${state.errorMessage}',
  };
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.networkUnavailable),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
