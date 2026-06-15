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
    final task = _task;
    if (task == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F5F9),
        appBar: AppBar(title: Text(_t(context, '任务详情', 'Task detail'))),
        body: Center(
          child: Text(
            _t(context, '任务信息不存在', 'Task information is unavailable'),
            style: const TextStyle(color: Color(0xFF8C919A), fontSize: 15),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
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
                      style: const TextStyle(
                        color: Color(0xFF303236),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (task.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        task.description,
                        style: const TextStyle(
                          color: Color(0xFF7D828A),
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
                  _divider(),
                  _DetailRow(
                    label: _t(context, '任务来源', 'Source'),
                    value: _sourceLabel(context, task),
                  ),
                  _divider(),
                  _DetailRow(
                    label: _t(context, '奖励分数', 'Reward'),
                    value: '${task.pointsReward}',
                  ),
                  if (task.reminders.isNotEmpty) ...[
                    _divider(),
                    _DetailWrapRow(
                      label: _t(context, '提醒时间', 'Reminders'),
                      values: task.reminders,
                    ),
                  ],
                  if (task.attachments.isNotEmpty) ...[
                    _divider(),
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
                onPressed: _submitting ? null : () => _updateStatus(task, 1),
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
                  side: const BorderSide(color: Color(0xFFE4E7EC)),
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

  Future<void> _updateStatus(DailyTask task, int status) async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(planRepositoryProvider)
          .updateTaskStatus(taskId: task.id, status: status);
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9AA0A8), fontSize: 15),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF303236),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9AA0A8), fontSize: 15),
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
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF303236),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
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

Widget _divider() => const Divider(height: 1, color: Color(0xFFE8EBF1));

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
