import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/plan_controller.dart';
import '../data/plan_models.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(currentPlansProvider);
    final tasks = ref.watch(dailyTasksProvider);
    final assessments = ref.watch(assessmentResultsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentPlansProvider);
        ref.invalidate(dailyTasksProvider);
        ref.invalidate(assessmentResultsProvider);
        await ref.read(dailyTasksProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SectionHeader(title: context.l10n.planCurrent),
          plans.when(
            data: (items) => items.isEmpty
                ? _EmptyPanel(message: context.l10n.planEmpty)
                : Column(
                    children: [for (final plan in items) _PlanCard(plan: plan)],
                  ),
            error: (error, stackTrace) =>
                _EmptyPanel(message: context.l10n.networkUnavailable),
            loading: () => const _LoadingPanel(),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: context.l10n.planTodayTasks),
          tasks.when(
            data: (page) => page.list.isEmpty
                ? _EmptyPanel(message: context.l10n.planTaskEmpty)
                : Column(
                    children: [
                      for (final task in page.list) _TaskCard(task: task),
                    ],
                  ),
            error: (error, stackTrace) =>
                _EmptyPanel(message: context.l10n.networkUnavailable),
            loading: () => const _LoadingPanel(),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: context.l10n.planAssessments),
          assessments.when(
            data: (page) => page.list.isEmpty
                ? _EmptyPanel(message: context.l10n.planAssessmentEmpty)
                : Column(
                    children: [
                      for (final result in page.list)
                        _AssessmentCard(result: result),
                    ],
                  ),
            error: (error, stackTrace) =>
                _EmptyPanel(message: context.l10n.networkUnavailable),
            loading: () => const _LoadingPanel(),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final TreatmentPlan plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.title, style: Theme.of(context).textTheme.titleMedium),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(plan.description),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (plan.startDate.isNotEmpty || plan.endDate.isNotEmpty)
                  Chip(label: Text(_planRange(context, plan))),
                Chip(label: Text(_planStatus(context, plan.status))),
              ],
            ),
            if (plan.stages.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final stage in plan.stages)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(stage.stageName),
                  subtitle: stage.description.isEmpty
                      ? null
                      : Text(stage.description),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task});

  final DailyTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isFinished = task.isDone || task.isSkipped;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_taskIcon(task.taskType), color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Chip(label: Text(_taskStatus(context, task.status))),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(task.description),
            ],
            const SizedBox(height: 8),
            Text(
              _taskMeta(context, task),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (!isFinished) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _updateTask(context, ref, 1),
                    icon: const Icon(Icons.check),
                    label: Text(context.l10n.planTaskComplete),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _updateTask(context, ref, 2),
                    icon: const Icon(Icons.skip_next_outlined),
                    label: Text(context.l10n.planTaskSkip),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateTask(
    BuildContext context,
    WidgetRef ref,
    int status,
  ) async {
    try {
      await ref
          .read(planRepositoryProvider)
          .updateTaskStatus(taskId: task.id, status: status);
      ref.invalidate(dailyTasksProvider);
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(context.l10n.planTaskUpdated);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.result});

  final AssessmentResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.fact_check_outlined),
        title: Text(result.assessmentTitle),
        subtitle: Text(
          [
            if (result.assessedAt.isNotEmpty) result.assessedAt,
            if (result.resultLevel.isNotEmpty) result.resultLevel,
            if (result.questionCount > 0)
              '${result.achievedScore}/${result.totalScore}',
          ].join('  '),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

String _planRange(BuildContext context, TreatmentPlan plan) {
  if (plan.startDate.isEmpty && plan.endDate.isEmpty) {
    return context.l10n.planNoDate;
  }
  if (plan.endDate.isEmpty) {
    return plan.startDate;
  }
  if (plan.startDate.isEmpty) {
    return plan.endDate;
  }
  return '${plan.startDate} - ${plan.endDate}';
}

String _planStatus(BuildContext context, int status) {
  return switch (status) {
    1 => context.l10n.planStatusActive,
    2 => context.l10n.planStatusPaused,
    3 => context.l10n.planStatusFinished,
    _ => context.l10n.planStatusDraft,
  };
}

String _taskStatus(BuildContext context, int status) {
  return switch (status) {
    1 => context.l10n.planTaskDone,
    2 => context.l10n.planTaskSkipped,
    3 => context.l10n.planTaskDelayed,
    _ => context.l10n.planTaskTodo,
  };
}

IconData _taskIcon(String type) {
  return switch (type) {
    'assessment' => Icons.assignment_outlined,
    'material' => Icons.menu_book_outlined,
    'checkin' => Icons.edit_note_outlined,
    _ => Icons.event_available_outlined,
  };
}

String _taskMeta(BuildContext context, DailyTask task) {
  final parts = [
    if (task.taskDate.isNotEmpty) task.taskDate,
    if (task.startTime.isNotEmpty) task.startTime,
    if (task.pointsReward > 0) '+${task.pointsReward}',
  ];
  return parts.isEmpty ? context.l10n.planNoDate : parts.join('  ');
}
