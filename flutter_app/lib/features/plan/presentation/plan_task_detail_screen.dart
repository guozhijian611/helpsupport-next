import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/plan_controller.dart';
import '../data/plan_models.dart';

class PlanTaskDetailScreen extends ConsumerStatefulWidget {
  const PlanTaskDetailScreen({super.key, required this.task});

  final DailyTask? task;

  @override
  ConsumerState<PlanTaskDetailScreen> createState() =>
      _PlanTaskDetailScreenState();
}

class _PlanTaskDetailScreenState extends ConsumerState<PlanTaskDetailScreen> {
  bool _submitting = false;

  DailyTask? get _task => widget.task;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanTaskDetailPalette.of(context);
    final task = _task;
    if (task == null) {
      return Scaffold(
        backgroundColor: palette.pageBackground,
        appBar: AppBar(
          backgroundColor: palette.pageBackground,
          foregroundColor: palette.primaryText,
          surfaceTintColor: Colors.transparent,
          title: Text(_t(context, '任务详情', 'Task detail')),
        ),
        body: Center(
          child: Text(
            _t(context, '任务信息不存在', 'Task information is unavailable'),
            style: TextStyle(color: palette.mutedText, fontSize: 15),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(_t(context, '任务详情', 'Task detail')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            _DetailCard(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (task.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        task.description,
                        style: TextStyle(
                          color: palette.mutedText,
                          fontSize: 16,
                          height: 1.7,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InfoChip(
                          label: _taskTypeLabel(context, task.taskType),
                        ),
                        _InfoChip(label: _statusLabel(context, task)),
                        if (_timeRange(task).isNotEmpty)
                          _InfoChip(label: _timeRange(task)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DetailCard(
              child: Column(
                children: [
                  _DetailRow(
                    label: _t(context, '任务日期', 'Task date'),
                    value: task.taskDate,
                  ),
                  _divider(context),
                  _DetailRow(
                    label: _t(context, '任务来源', 'Source'),
                    value: _sourceLabel(context, task),
                  ),
                  _divider(context),
                  _DetailRow(
                    label: _t(context, '奖励分数', 'Reward'),
                    value: '${task.pointsReward}',
                  ),
                  if (task.requiresFeedback) ...[
                    _divider(context),
                    _DetailTextBlock(
                      label: _t(context, '反馈要求', 'Feedback prompt'),
                      value: task.feedbackPrompt.trim().isEmpty
                          ? _t(
                              context,
                              '完成任务时请填写你的反馈内容。',
                              'Please enter feedback when completing this task.',
                            )
                          : task.feedbackPrompt,
                    ),
                  ],
                  if (task.feedbackContent.trim().isNotEmpty) ...[
                    _divider(context),
                    _DetailTextBlock(
                      label: _t(context, '我的反馈', 'My feedback'),
                      value: task.feedbackContent,
                    ),
                  ],
                  if (task.reminders.isNotEmpty) ...[
                    _divider(context),
                    _DetailWrapRow(
                      label: _t(context, '提醒时间', 'Reminders'),
                      values: task.reminders,
                    ),
                  ],
                  if (task.attachments.isNotEmpty) ...[
                    _divider(context),
                    _DetailWrapRow(
                      label: _t(context, '附件', 'Attachments'),
                      values: task.attachments,
                    ),
                  ],
                ],
              ),
            ),
            if (_submitting)
              const Padding(
                padding: EdgeInsets.only(top: 18),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!task.isDone && !task.isSkipped) ...[
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _submitting ? null : () => _completeTask(task),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF5A81DA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(_t(context, '完成任务', 'Complete task')),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _submitting ? null : () => _updateStatus(task, 2),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: BorderSide(color: palette.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(_t(context, '暂时跳过', 'Skip for now')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _completeTask(DailyTask task) async {
    String feedbackContent = '';
    if (task.requiresFeedback) {
      final value = await _showFeedbackInput(task);
      if (!mounted || value == null) {
        return;
      }
      feedbackContent = value.trim();
      if (feedbackContent.isEmpty) {
        context.showCenteredNotice(
          _t(context, '请先填写反馈内容', 'Please enter feedback first'),
        );
        return;
      }
    }
    await _updateStatus(task, 1, feedbackContent: feedbackContent);
  }

  Future<String?> _showFeedbackInput(DailyTask task) async {
    final controller = TextEditingController();
    final palette = _PlanTaskDetailPalette.of(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _t(context, '填写任务反馈', 'Task feedback'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      task.feedbackPrompt.trim().isEmpty
                          ? _t(
                              context,
                              '请记录这次任务后的感受、结果或需要医生了解的内容。',
                              'Record feelings, results, or anything your doctor should know.',
                            )
                          : task.feedbackPrompt,
                      style: TextStyle(
                        color: palette.mutedText,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      minLines: 4,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: _t(context, '请输入反馈内容', 'Enter feedback'),
                        filled: true,
                        fillColor: palette.softBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(controller.text),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: const Color(0xFFFF9585),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(_t(context, '提交并完成', 'Submit and complete')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _updateStatus(
    DailyTask task,
    int status, {
    String feedbackContent = '',
  }) async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(planRepositoryProvider)
          .updateTaskStatus(
            taskId: task.id,
            status: status,
            feedbackContent: feedbackContent,
          );
      ref.invalidate(dailyTasksProvider);
      ref.invalidate(dailyTasksByDateProvider(task.taskDate));
      ref.invalidate(assessmentResultsProvider);
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        status == 1
            ? context.l10n.planTaskUpdated
            : _t(context, '任务已跳过', 'Task skipped'),
      );
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanTaskDetailPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanTaskDetailPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: palette.secondaryText, fontSize: 15),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailWrapRow extends StatelessWidget {
  const _DetailWrapRow({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanTaskDetailPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: palette.secondaryText, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final value in values)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.softBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailTextBlock extends StatelessWidget {
  const _DetailTextBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanTaskDetailPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: palette.secondaryText, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanTaskDetailPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5A81DA),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Widget _divider(BuildContext context) {
  return Divider(height: 1, color: _PlanTaskDetailPalette.of(context).outline);
}

class _PlanTaskDetailPalette {
  const _PlanTaskDetailPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.outline,
  });

  factory _PlanTaskDetailPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _PlanTaskDetailPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      softBackground: scheme.surfaceContainerLow,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
          : const Color(0xFF8C919A),
      outline: scheme.outlineVariant,
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color outline;
}

String _statusLabel(BuildContext context, DailyTask task) {
  if (task.isDone) {
    return _t(context, '已完成', 'Completed');
  }
  if (task.isSkipped) {
    return _t(context, '已跳过', 'Skipped');
  }
  return _t(context, '待完成', 'Pending');
}

String _timeRange(DailyTask task) {
  if (task.startTime.trim().isEmpty && task.endTime.trim().isEmpty) {
    return '';
  }
  if (task.startTime.trim().isEmpty) {
    return task.endTime.trim();
  }
  if (task.endTime.trim().isEmpty) {
    return task.startTime.trim();
  }
  return '${task.startTime.trim()}-${task.endTime.trim()}';
}

String _taskTypeLabel(BuildContext context, String value) {
  switch (value) {
    case 'assessment':
      return _t(context, '评估量表', 'Assessment');
    case 'material':
      return _t(context, '教育素材', 'Material');
    case 'checkin':
      return _t(context, '打卡记录', 'Check-in');
    default:
      return _t(context, '日常任务', 'Daily task');
  }
}

String _sourceLabel(BuildContext context, DailyTask task) {
  switch (task.source) {
    case 'chat':
      return _t(context, 'AI 医生对话', 'AI doctor chat');
    case 'doctor':
      return _t(context, '医生安排', 'Doctor assignment');
    case 'assessment':
      return _t(context, '评估量表', 'Assessment scale');
    case 'material':
      return _t(context, '素材学习', 'Material learning');
    case 'ai':
      return _t(context, 'AI 心理医生', 'AI doctor');
    default:
      return _t(context, '治疗计划', 'Treatment plan');
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
