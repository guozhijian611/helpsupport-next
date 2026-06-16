import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/local_llm/llama_engine.dart';
import '../../local_model/application/local_model_controller.dart';
import '../../local_model/data/local_model_models.dart';

class AiCapabilityTestScreen extends ConsumerStatefulWidget {
  const AiCapabilityTestScreen({super.key});

  @override
  ConsumerState<AiCapabilityTestScreen> createState() =>
      _AiCapabilityTestScreenState();
}

class _AiCapabilityTestScreenState
    extends ConsumerState<AiCapabilityTestScreen> {
  Future<void> _refresh() async {
    ref.invalidate(llamaRuntimeStatusProvider);
    ref.invalidate(localModelCatalogProvider);
    ref.invalidate(localModelDownloadControllerProvider);
    await Future.wait([
      ref.read(llamaRuntimeStatusProvider.future).catchError((_) {}),
      ref.read(localModelCatalogProvider.future).catchError((_) {}),
      ref.read(localModelDownloadControllerProvider.future).catchError((_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _AiCapabilityPalette.of(context);
    final runtimeStatus = ref.watch(llamaRuntimeStatusProvider);
    final catalog = ref.watch(localModelCatalogProvider);
    final downloadStates = ref.watch(localModelDownloadControllerProvider);
    final snapshot = _AiCapabilitySnapshot.from(
      runtimeStatus: runtimeStatus,
      catalog: catalog,
      downloadStates: downloadStates,
    );

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: Text(context.l10n.aiCapabilityTestTitle),
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: context.l10n.diagnosticsRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: palette.accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _SummaryCard(
                palette: palette,
                snapshot: snapshot,
                onOpenLocalModels: () => context.push('/local-model'),
                onStartChat: snapshot.firstReadyModel == null
                    ? null
                    : () => _openLocalChat(snapshot.firstReadyModel!),
              ),
              const SizedBox(height: 18),
              _DetailCard(
                palette: palette,
                title: context.l10n.aiCapabilityTestOverviewTitle,
                children: [
                  _StatusRow(
                    palette: palette,
                    icon: snapshot.runtimeReady
                        ? Icons.check_circle_outline_rounded
                        : snapshot.runtimeLoading
                        ? Icons.sync_rounded
                        : Icons.error_outline_rounded,
                    label: context.l10n.aiCapabilityTestRuntimeLabel,
                    value: snapshot.runtimeLoading
                        ? context.l10n.localModelRuntimeChecking
                        : snapshot.runtimeReady
                        ? context.l10n.aiCapabilityTestRuntimeReadyValue
                        : context.l10n.aiCapabilityTestRuntimeUnavailableValue,
                    valueColor: snapshot.runtimeReady
                        ? palette.success
                        : snapshot.runtimeLoading
                        ? palette.primaryText
                        : palette.danger,
                    details: snapshot.runtimeError.isEmpty
                        ? null
                        : snapshot.runtimeError,
                  ),
                  _StatusRow(
                    palette: palette,
                    icon: Icons.memory_rounded,
                    label: context.l10n.aiCapabilityTestLibraryPathLabel,
                    value: snapshot.runtimePath.isEmpty
                        ? '--'
                        : snapshot.runtimePath,
                  ),
                  _StatusRow(
                    palette: palette,
                    icon: Icons.developer_board_rounded,
                    label: context.l10n.aiCapabilityTestCpuLabel,
                    value: context.l10n.aiCapabilityTestCountCores(
                      snapshot.processorCount,
                    ),
                  ),
                  _StatusRow(
                    palette: palette,
                    icon: Icons.grid_view_rounded,
                    label: context.l10n.aiCapabilityTestCatalogLabel,
                    value: snapshot.catalogCount == null
                        ? '--'
                        : context.l10n.aiCapabilityTestCountModels(
                            snapshot.catalogCount!,
                          ),
                    details: snapshot.catalogError,
                  ),
                  _StatusRow(
                    palette: palette,
                    icon: Icons.download_done_rounded,
                    label: context.l10n.aiCapabilityTestDownloadedLabel,
                    value: context.l10n.aiCapabilityTestCountDownloaded(
                      snapshot.downloadedCount,
                    ),
                  ),
                  _StatusRow(
                    palette: palette,
                    icon: Icons.stacked_bar_chart_rounded,
                    label: context.l10n.aiCapabilityTestMinMemoryLabel,
                    value: snapshot.minMemoryMb == null
                        ? '--'
                        : context.l10n.aiCapabilityTestMemoryRequirement(
                            snapshot.minMemoryMb!,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLocalChat(LocalModelItem item) {
    context.push(
      Uri(
        path: '/local-model/chat/${item.id}',
        queryParameters: {
          'mode': 'companion',
          'title': context.l10n.aiCapabilityTestStartChat,
        },
      ).toString(),
    );
  }
}

class _AiCapabilitySnapshot {
  const _AiCapabilitySnapshot({
    required this.runtimeLoading,
    required this.runtimeReady,
    required this.runtimePath,
    required this.runtimeError,
    required this.processorCount,
    required this.catalogCount,
    required this.catalogError,
    required this.downloadedCount,
    required this.minMemoryMb,
    required this.firstReadyModel,
  });

  factory _AiCapabilitySnapshot.from({
    required AsyncValue<LlamaRuntimeStatus> runtimeStatus,
    required AsyncValue<List<LocalModelItem>> catalog,
    required AsyncValue<Map<int, LocalModelDownloadState>> downloadStates,
  }) {
    final runtime = runtimeStatus.hasValue ? runtimeStatus.value : null;
    final items = catalog.hasValue ? catalog.value : null;
    final states = downloadStates.hasValue
        ? downloadStates.value ?? const <int, LocalModelDownloadState>{}
        : const <int, LocalModelDownloadState>{};

    LocalModelItem? firstReadyModel;
    if (items != null) {
      for (final item in items) {
        if (states[item.id]?.isReady == true) {
          firstReadyModel = item;
          break;
        }
      }
    }

    final downloadedCount = items == null
        ? states.values.where((state) => state.isReady).length
        : items.where((item) => states[item.id]?.isReady == true).length;
    final minMemoryMb = items == null
        ? null
        : items
              .map((item) => item.minMemoryMb)
              .where((value) => value > 0)
              .fold<int?>(null, (current, value) {
                if (current == null || value < current) {
                  return value;
                }
                return current;
              });

    return _AiCapabilitySnapshot(
      runtimeLoading: runtimeStatus.isLoading,
      runtimeReady: runtime?.isAvailable == true,
      runtimePath: runtime?.libraryPath ?? '',
      runtimeError: runtime?.errorMessage ?? '',
      processorCount: Platform.numberOfProcessors,
      catalogCount: items?.length,
      catalogError: catalog.hasError ? catalog.error.toString() : null,
      downloadedCount: downloadedCount,
      minMemoryMb: minMemoryMb,
      firstReadyModel: firstReadyModel,
    );
  }

  final bool runtimeLoading;
  final bool runtimeReady;
  final String runtimePath;
  final String runtimeError;
  final int processorCount;
  final int? catalogCount;
  final String? catalogError;
  final int downloadedCount;
  final int? minMemoryMb;
  final LocalModelItem? firstReadyModel;

  bool get canOpenChat => runtimeReady && firstReadyModel != null;

  String headline(BuildContext context) {
    if (runtimeLoading) {
      return context.l10n.aiCapabilityTestCheckingHeadline;
    }
    if (!runtimeReady) {
      return context.l10n.aiCapabilityTestUnavailableHeadline;
    }
    return context.l10n.aiCapabilityTestReadyHeadline;
  }

  String body(BuildContext context) {
    if (runtimeLoading) {
      return context.l10n.aiCapabilityTestCheckingBody;
    }
    if (!runtimeReady) {
      final base = context.l10n.aiCapabilityTestUnavailableBody;
      if (runtimeError.trim().isEmpty) {
        return base;
      }
      return '$base\n$runtimeError';
    }
    if (firstReadyModel != null) {
      return context.l10n.aiCapabilityTestReadyWithModelBody;
    }
    return context.l10n.aiCapabilityTestReadyWithoutModelBody;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.palette,
    required this.snapshot,
    required this.onOpenLocalModels,
    required this.onStartChat,
  });

  final _AiCapabilityPalette palette;
  final _AiCapabilitySnapshot snapshot;
  final VoidCallback onOpenLocalModels;
  final VoidCallback? onStartChat;

  @override
  Widget build(BuildContext context) {
    final gradient = snapshot.runtimeReady
        ? palette.readyGradient
        : snapshot.runtimeLoading
        ? palette.loadingGradient
        : palette.errorGradient;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: gradient),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  snapshot.runtimeReady
                      ? Icons.auto_awesome_rounded
                      : snapshot.runtimeLoading
                      ? Icons.sync_rounded
                      : Icons.block_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  snapshot.headline(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            snapshot.body(context),
            style: const TextStyle(
              color: Color(0xFFFFF8F6),
              fontSize: 14,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: onOpenLocalModels,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: gradient.last,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.download_for_offline_rounded, size: 18),
                label: Text(context.l10n.aiCapabilityTestOpenLocalModels),
              ),
              if (snapshot.canOpenChat)
                FilledButton.icon(
                  onPressed: onStartChat,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text(context.l10n.aiCapabilityTestStartChat),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.palette,
    required this.title,
    required this.children,
  });

  final _AiCapabilityPalette palette;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.details,
  });

  final _AiCapabilityPalette palette;
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final String? details;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: palette.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? palette.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                if (details != null && details!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details!,
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCapabilityPalette {
  const _AiCapabilityPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.iconBackground,
    required this.accent,
    required this.success,
    required this.danger,
    required this.readyGradient,
    required this.loadingGradient,
    required this.errorGradient,
  });

  factory _AiCapabilityPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _AiCapabilityPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      iconBackground: isDark
          ? const Color(0x26FFB4A8)
          : const Color(0x14FF9585),
      accent: isDark ? const Color(0xFFFFB4A8) : const Color(0xFFFF9585),
      success: isDark ? const Color(0xFF9DE2A4) : const Color(0xFF2F8F46),
      danger: isDark ? const Color(0xFFFFB4A8) : const Color(0xFFC94D41),
      readyGradient: isDark
          ? const [Color(0xFF9A5A52), Color(0xFFB46E65)]
          : const [Color(0xFFFF9585), Color(0xFFFCB08E)],
      loadingGradient: isDark
          ? const [Color(0xFF5A6886), Color(0xFF6F80A8)]
          : const [Color(0xFF7B9BE1), Color(0xFF9DB5EB)],
      errorGradient: isDark
          ? const [Color(0xFF7A4742), Color(0xFF965E58)]
          : const [Color(0xFFE68678), Color(0xFFF0A38F)],
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color iconBackground;
  final Color accent;
  final Color success;
  final Color danger;
  final List<Color> readyGradient;
  final List<Color> loadingGradient;
  final List<Color> errorGradient;
}
