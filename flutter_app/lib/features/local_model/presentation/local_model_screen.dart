import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../application/local_model_controller.dart';
import '../data/local_model_models.dart';

class LocalModelScreen extends ConsumerWidget {
  const LocalModelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(localModelCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.localModelTitle)),
      body: SafeArea(
        child: catalog.when(
          data: (items) => items.isEmpty
              ? _EmptyState(message: context.l10n.localModelSubtitle)
              : _CatalogList(items: items),
          error: (error, stackTrace) => _ErrorState(
            onRetry: () => ref.invalidate(localModelCatalogProvider),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _CatalogList extends StatelessWidget {
  const _CatalogList({required this.items});

  final List<LocalModelItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.memory_outlined),
            title: Text(item.name.isEmpty ? item.code : item.name),
            subtitle: Text(
              [
                if (item.provider.isNotEmpty) item.provider,
                if (item.modelFamily.isNotEmpty) item.modelFamily,
                if (item.quantization.isNotEmpty) item.quantization,
                if (item.minMemoryMb > 0) '${item.minMemoryMb} MB',
              ].join(' / '),
            ),
            trailing: const Icon(Icons.download_outlined),
          ),
        );
      },
    );
  }
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
