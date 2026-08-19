import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/local_llm/llama_engine.dart';
import '../../../core/notifications/centered_notice.dart';
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
  bool _runningSmokeTest = false;
  _AiSmokeTestResult? _smokeTestResult;

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

  Future<void> _downloadModel(LocalModelItem model) async {
    try {
      await ref
          .read(localModelDownloadControllerProvider.notifier)
          .download(model);
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        '${context.l10n.downloadModel} ${model.name.isEmpty ? model.code : model.name}',
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  Future<void> _runSmokeTest(_AiModelAction action) async {
    if (_runningSmokeTest || !action.state.isReady) {
      return;
    }

    setState(() => _runningSmokeTest = true);
    final stopwatch = Stopwatch()..start();
    try {
      final output = await ref
          .read(llamaEngineProvider)
          .generate(
            model: action.model,
            modelPath: action.state.filePath,
            systemPrompt:
                'You are a local AI self-check assistant. Reply in one short sentence only.',
            history: const [],
            userMessage: 'Reply with TEST OK.',
          );
      stopwatch.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _smokeTestResult = _AiSmokeTestResult(
          success: output.trim().isNotEmpty,
          modelName: action.displayName,
          durationMs: stopwatch.elapsedMilliseconds,
          output: output.trim(),
          testedAt: DateTime.now(),
        );
      });
      context.showCenteredNotice(
        context.l10n.aiCapabilityTestSmokeSuccessNotice,
      );
    } on Object catch (error) {
      stopwatch.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _smokeTestResult = _AiSmokeTestResult(
          success: false,
          modelName: action.displayName,
          durationMs: stopwatch.elapsedMilliseconds,
          error: error.toString(),
          testedAt: DateTime.now(),
        );
      });
      context.showCenteredNotice(
        context.l10n.aiCapabilityTestSmokeFailureNotice,
      );
    } finally {
      if (mounted) {
        setState(() => _runningSmokeTest = false);
      }
    }
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
                onDownloadRecommended: snapshot.firstDownloadAction == null
                    ? null
                    : () => _downloadModel(snapshot.firstDownloadAction!.model),
                onStartChat: snapshot.firstReadyAction == null
                    ? null
                    : () => _openLocalChat(snapshot.firstReadyAction!.model),
              ),
              const SizedBox(height: 18),
              _SmokeTestCard(
                palette: palette,
                snapshot: snapshot,
                running: _runningSmokeTest,
                result: _smokeTestResult,
                onRun: snapshot.firstReadyAction == null
                    ? null
                    : () => _runSmokeTest(snapshot.firstReadyAction!),
                onDownloadRecommended: snapshot.firstDownloadAction == null
                    ? null
                    : () => _downloadModel(snapshot.firstDownloadAction!.model),
                onOpenChat: snapshot.firstReadyAction == null
                    ? null
                    : () => _openLocalChat(snapshot.firstReadyAction!.model),
              ),
              if (snapshot.quickActions.isNotEmpty) ...[
                const SizedBox(height: 18),
                _ModelActionsCard(
                  palette: palette,
                  actions: snapshot.quickActions,
                  smokeTestModelId: snapshot.firstReadyAction?.model.id,
                  recommendedModelId: snapshot.firstDownloadAction?.model.id,
                  onDownload: _downloadModel,
                  onOpenChat: _openLocalChat,
                ),
              ],
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
          'title': context.l10n.aiCapabilityTestTryChat,
        },
      ).toString(),
    );
  }
}

class _AiSmokeTestResult {
  const _AiSmokeTestResult({
    required this.success,
    required this.modelName,
    required this.durationMs,
    required this.testedAt,
    this.output = '',
    this.error = '',
  });

  final bool success;
  final String modelName;
  final int durationMs;
  final DateTime testedAt;
  final String output;
  final String error;
}

class _AiModelAction {
  const _AiModelAction({required this.model, required this.state});

  final LocalModelItem model;
  final LocalModelDownloadState state;

  String get displayName => model.name.isEmpty ? model.code : model.name;

  String metaText(BuildContext context) {
    return [
      if (model.provider.isNotEmpty) model.provider,
      if (model.modelFamily.isNotEmpty) model.modelFamily,
      if (model.quantization.isNotEmpty) model.quantization,
      if (model.fileSize > 0) _formatBytes(model.fileSize),
      if (model.minMemoryMb > 0)
        context.l10n.aiCapabilityTestMemoryRequirement(model.minMemoryMb),
    ].join(' / ');
  }

  String actionLabel(BuildContext context) {
    return switch (state.status) {
      LocalModelDownloadStatus.ready => context.l10n.aiCapabilityTestTryChat,
      LocalModelDownloadStatus.downloading => context.l10n.modelDownloading,
      LocalModelDownloadStatus.verifying => context.l10n.modelVerifying,
      LocalModelDownloadStatus.failed => context.l10n.retry,
      LocalModelDownloadStatus.notDownloaded => context.l10n.downloadModel,
    };
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
    required this.firstReadyAction,
    required this.firstDownloadAction,
    required this.quickActions,
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
    final actions = (items ?? const <LocalModelItem>[])
        .where((item) => item.capability == 'llm' || item.capability.isEmpty)
        .map(
          (item) => _AiModelAction(
            model: item,
            state:
                states[item.id] ??
                const LocalModelDownloadState.notDownloaded(),
          ),
        )
        .toList(growable: false);
    final sorted = [...actions]..sort(_compareActions);
    final firstReadyAction = sorted
        .where((item) => item.state.isReady)
        .firstOrNull;
    final firstDownloadAction = sorted
        .where((item) => !item.state.isReady && !item.state.isBusy)
        .firstOrNull;
    final downloadedCount = actions.where((item) => item.state.isReady).length;
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
      firstReadyAction: firstReadyAction,
      firstDownloadAction: firstDownloadAction,
      quickActions: sorted.take(3).toList(growable: false),
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
  final _AiModelAction? firstReadyAction;
  final _AiModelAction? firstDownloadAction;
  final List<_AiModelAction> quickActions;

  bool get canOpenChat => runtimeReady && firstReadyAction != null;

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
    if (firstReadyAction != null) {
      return context.l10n.aiCapabilityTestReadyWithModelBody;
    }
    return context.l10n.aiCapabilityTestReadyWithoutModelBody;
  }
}

int _compareActions(_AiModelAction left, _AiModelAction right) {
  final leftPriority = (
    left.state.isReady ? 0 : 1,
    left.state.isBusy ? 0 : 1,
    left.model.minMemoryMb <= 0 ? 1 << 20 : left.model.minMemoryMb,
    left.model.fileSize <= 0 ? 1 << 30 : left.model.fileSize,
  );
  final rightPriority = (
    right.state.isReady ? 0 : 1,
    right.state.isBusy ? 0 : 1,
    right.model.minMemoryMb <= 0 ? 1 << 20 : right.model.minMemoryMb,
    right.model.fileSize <= 0 ? 1 << 30 : right.model.fileSize,
  );
  final first = leftPriority.$1.compareTo(rightPriority.$1);
  if (first != 0) {
    return first;
  }
  final second = leftPriority.$2.compareTo(rightPriority.$2);
  if (second != 0) {
    return second;
  }
  final third = leftPriority.$3.compareTo(rightPriority.$3);
  if (third != 0) {
    return third;
  }
  return leftPriority.$4.compareTo(rightPriority.$4);
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.palette,
    required this.snapshot,
    required this.onOpenLocalModels,
    required this.onDownloadRecommended,
    required this.onStartChat,
  });

  final _AiCapabilityPalette palette;
  final _AiCapabilitySnapshot snapshot;
  final VoidCallback onOpenLocalModels;
  final VoidCallback? onDownloadRecommended;
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
                  label: Text(context.l10n.aiCapabilityTestTryChat),
                )
              else if (onDownloadRecommended != null)
                FilledButton.icon(
                  onPressed: onDownloadRecommended,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: Text(context.l10n.aiCapabilityTestRecommendedDownload),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmokeTestCard extends StatelessWidget {
  const _SmokeTestCard({
    required this.palette,
    required this.snapshot,
    required this.running,
    required this.result,
    required this.onRun,
    required this.onDownloadRecommended,
    required this.onOpenChat,
  });

  final _AiCapabilityPalette palette;
  final _AiCapabilitySnapshot snapshot;
  final bool running;
  final _AiSmokeTestResult? result;
  final VoidCallback? onRun;
  final VoidCallback? onDownloadRecommended;
  final VoidCallback? onOpenChat;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      palette: palette,
      title: context.l10n.aiCapabilityTestSmokeTitle,
      children: [
        if (running) ...[
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.aiCapabilityTestSmokeRunning,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ] else if (result != null) ...[
          _SmokeResultView(palette: palette, result: result!),
          const SizedBox(height: 12),
        ] else ...[
          Text(
            snapshot.firstReadyAction != null
                ? context.l10n.aiCapabilityTestSmokeReadyHint
                : context.l10n.aiCapabilityTestSmokeNeedModelHint,
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: running ? null : onRun,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                result == null
                    ? context.l10n.aiCapabilityTestSmokeRunButton
                    : context.l10n.aiCapabilityTestSmokeRerunButton,
              ),
            ),
            if (snapshot.firstReadyAction == null &&
                onDownloadRecommended != null)
              OutlinedButton.icon(
                onPressed: running ? null : onDownloadRecommended,
                icon: const Icon(Icons.file_download_outlined),
                label: Text(context.l10n.aiCapabilityTestRecommendedDownload),
              ),
            if (snapshot.firstReadyAction != null && onOpenChat != null)
              OutlinedButton.icon(
                onPressed: running ? null : onOpenChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text(context.l10n.aiCapabilityTestTryChat),
              ),
          ],
        ),
      ],
    );
  }
}

class _SmokeResultView extends StatelessWidget {
  const _SmokeResultView({required this.palette, required this.result});

  final _AiCapabilityPalette palette;
  final _AiSmokeTestResult result;

  @override
  Widget build(BuildContext context) {
    final accent = result.success ? palette.success : palette.danger;
    final output = result.success ? result.output : result.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.success
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.success
                      ? context.l10n.aiCapabilityTestSmokeSuccessTitle
                      : context.l10n.aiCapabilityTestSmokeFailureTitle,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MiniMetaRow(
            label: context.l10n.aiCapabilityTestSmokeModelLabel,
            value: result.modelName,
            palette: palette,
          ),
          _MiniMetaRow(
            label: context.l10n.aiCapabilityTestSmokeDurationLabel,
            value: '${result.durationMs} ms',
            palette: palette,
          ),
          _MiniMetaRow(
            label: result.success
                ? context.l10n.aiCapabilityTestSmokeOutputLabel
                : context.l10n.aiCapabilityTestSmokeErrorLabel,
            value: output.trim().isEmpty ? '--' : output.trim(),
            palette: palette,
            multiline: true,
          ),
        ],
      ),
    );
  }
}

class _MiniMetaRow extends StatelessWidget {
  const _MiniMetaRow({
    required this.label,
    required this.value,
    required this.palette,
    this.multiline = false,
  });

  final String label;
  final String value;
  final _AiCapabilityPalette palette;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
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
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: multiline ? 6 : 1,
            overflow: multiline ? TextOverflow.ellipsis : TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelActionsCard extends StatelessWidget {
  const _ModelActionsCard({
    required this.palette,
    required this.actions,
    required this.smokeTestModelId,
    required this.recommendedModelId,
    required this.onDownload,
    required this.onOpenChat,
  });

  final _AiCapabilityPalette palette;
  final List<_AiModelAction> actions;
  final int? smokeTestModelId;
  final int? recommendedModelId;
  final Future<void> Function(LocalModelItem model) onDownload;
  final void Function(LocalModelItem model) onOpenChat;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      palette: palette,
      title: context.l10n.aiCapabilityTestQuickModelsTitle,
      children: [
        Text(
          context.l10n.aiCapabilityTestQuickModelsSubtitle,
          style: TextStyle(
            color: palette.secondaryText,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < actions.length; index++) ...[
          _ModelActionRow(
            palette: palette,
            action: actions[index],
            recommended: actions[index].model.id == recommendedModelId,
            smokeReady: actions[index].model.id == smokeTestModelId,
            onDownload: () => onDownload(actions[index].model),
            onOpenChat: () => onOpenChat(actions[index].model),
          ),
          if (index != actions.length - 1)
            Divider(height: 22, color: palette.divider),
        ],
      ],
    );
  }
}

class _ModelActionRow extends StatelessWidget {
  const _ModelActionRow({
    required this.palette,
    required this.action,
    required this.recommended,
    required this.smokeReady,
    required this.onDownload,
    required this.onOpenChat,
  });

  final _AiCapabilityPalette palette;
  final _AiModelAction action;
  final bool recommended;
  final bool smokeReady;
  final VoidCallback onDownload;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final buttonChild = action.state.isBusy
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: palette.accent,
            ),
          )
        : Text(action.actionLabel(context));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    action.displayName,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (recommended)
                    _Tag(
                      label: context.l10n.aiCapabilityTestRecommendedTag,
                      background: palette.accent.withValues(alpha: 0.12),
                      foreground: palette.accent,
                    ),
                  if (smokeReady)
                    _Tag(
                      label: context.l10n.aiCapabilityTestSmokeReadyTag,
                      background: palette.success.withValues(alpha: 0.12),
                      foreground: palette.success,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                action.metaText(context),
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        action.state.isReady
            ? FilledButton(
                onPressed: onOpenChat,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: Colors.white,
                ),
                child: buttonChild,
              )
            : OutlinedButton(
                onPressed: action.state.isBusy ? null : onDownload,
                child: buttonChild,
              ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
    required this.divider,
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
      divider: scheme.outlineVariant.withValues(alpha: 0.4),
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
  final Color divider;
  final List<Color> readyGradient;
  final List<Color> loadingGradient;
  final List<Color> errorGradient;
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

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
