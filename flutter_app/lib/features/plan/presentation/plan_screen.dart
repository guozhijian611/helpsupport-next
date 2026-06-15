import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../auth/application/auth_controller.dart';
import '../../doctor/presentation/doctor_plan_screen.dart';
import '../application/plan_controller.dart';
import '../data/plan_models.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _selectedKey => _formatDate(_selectedDate);

  @override
  Widget build(BuildContext context) {
    final palette = _PlanPalette.of(context);
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (session?.currentRole == 'doctor') {
      return const DoctorPlanScreen();
    }

    final plans = ref.watch(currentPlansProvider);
    final tasks = ref.watch(dailyTasksByDateProvider(_selectedKey));
    final assessments = ref.watch(assessmentResultsProvider);
    final taskPage = switch (tasks) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final nickname = _firstText([
      session?.profile['nickname'],
      session?.member['nickname'],
      session?.member['username'],
    ], fallback: 'Alexandrina');

    return ColoredBox(
      color: palette.pageBackground,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentPlansProvider);
          ref.invalidate(dailyTasksByDateProvider(_selectedKey));
          ref.invalidate(assessmentResultsProvider);
          await Future.wait([
            ref.read(currentPlansProvider.future),
            ref.read(dailyTasksByDateProvider(_selectedKey).future),
            ref.read(assessmentResultsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          children: [
            _PlanHeader(
              name: nickname,
              onNotificationTap: () => context.push('/me/messages'),
            ),
            const SizedBox(height: 20),
            plans.when(
              data: (items) => _PlanSummaryCard(
                plan: items.isEmpty ? null : items.first,
                completedCount:
                    taskPage?.list.where((task) => task.isDone).length ?? 0,
                totalCount: taskPage?.list.length ?? 0,
                selectedDate: _selectedDate,
              ),
              error: (error, _) => _StatusCard(
                title: context.l10n.networkUnavailable,
                message: error.toString(),
              ),
              loading: () => const _SummaryLoadingCard(),
            ),
            const SizedBox(height: 18),
            _WeekSwitcher(
              selectedDate: _selectedDate,
              onPreviousWeek: () => setState(
                () => _selectedDate = _selectedDate.subtract(
                  const Duration(days: 7),
                ),
              ),
              onNextWeek: () => setState(
                () =>
                    _selectedDate = _selectedDate.add(const Duration(days: 7)),
              ),
            ),
            const SizedBox(height: 14),
            _WeekStrip(
              selectedDate: _selectedDate,
              onSelected: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 10),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 34,
              color: palette.secondaryText,
            ),
            const SizedBox(height: 14),
            _SectionTitle(title: _t(context, '当日任务', "Today's tasks")),
            const SizedBox(height: 12),
            tasks.when(
              data: (page) => page.list.isEmpty
                  ? _StatusCard(
                      title: context.l10n.planTaskEmpty,
                      message: _t(
                        context,
                        '这一天没有排定任务，你可以切换日期查看其它安排。',
                        'No tasks are scheduled for this day. Try another date.',
                      ),
                    )
                  : Column(
                      children: [
                        for (final task in page.list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _TaskScheduleCard(
                              task: task,
                              onStatusChanged: () => _completeTask(task),
                              onOpen: () => _openTask(context, task),
                            ),
                          ),
                      ],
                    ),
              error: (error, _) => _StatusCard(
                title: context.l10n.networkUnavailable,
                message: error.toString(),
              ),
              loading: () => const _SummaryLoadingCard(height: 220),
            ),
            const SizedBox(height: 10),
            _SectionTitle(title: _t(context, '评估量表', 'Assessments')),
            const SizedBox(height: 12),
            assessments.when(
              data: (page) => page.list.isEmpty
                  ? _StatusCard(
                      title: context.l10n.planAssessmentEmpty,
                      message: _t(
                        context,
                        '完成量表后，这里会出现你的评分与建议。',
                        'Assessment scores and suggestions will appear here.',
                      ),
                    )
                  : Column(
                      children: [
                        for (final item in page.list.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AssessmentInsightCard(result: item),
                          ),
                      ],
                    ),
              error: (error, _) => _StatusCard(
                title: context.l10n.networkUnavailable,
                message: error.toString(),
              ),
              loading: () => const _SummaryLoadingCard(height: 200),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeTask(DailyTask task) async {
    try {
      await ref
          .read(planRepositoryProvider)
          .updateTaskStatus(taskId: task.id, status: 1);
      ref.invalidate(dailyTasksByDateProvider(_selectedKey));
      ref.invalidate(dailyTasksProvider);
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(context.l10n.planTaskUpdated);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  void _openTask(BuildContext context, DailyTask task) {
    if (task.taskType == 'assessment' || task.source == 'assessment') {
      context.push('/plan/assessment/${task.id}');
      return;
    }
    if (task.taskType == 'material' || task.source == 'material') {
      context.push('/materials?type=education');
      return;
    }
    if (task.source == 'chat' ||
        task.source == 'doctor' ||
        task.source == 'ai') {
      context.push('/chat');
      return;
    }
    context.push('/plan/task/${task.id}', extra: task);
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.name, required this.onNotificationTap});

  final String name;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanPalette.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: palette.avatarBackground,
          child: const Icon(Icons.person_rounded, color: Color(0xFFFF9585)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(context, 'Good morning!', 'Good morning!'),
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: palette.cardBackground,
            foregroundColor: palette.primaryText,
          ),
          onPressed: onNotificationTap,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({
    required this.plan,
    required this.completedCount,
    required this.totalCount,
    required this.selectedDate,
  });

  final TreatmentPlan? plan;
  final int completedCount;
  final int totalCount;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final currentStage = _currentStage(plan);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF628AE1), Color(0xFF4F76D4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryLine(
            label: _t(context, '阶段名称', 'Stage'),
            value:
                currentStage?.stageName ??
                plan?.title ??
                _t(context, '暂无计划', 'No plan'),
          ),
          const SizedBox(height: 12),
          _SummaryLine(
            label: _t(context, '起止日期', 'Schedule'),
            value: _planRange(plan, selectedDate),
          ),
          const SizedBox(height: 12),
          _SummaryLine(
            label: _t(context, '阶段目标', 'Goal'),
            value: currentStage?.description.isNotEmpty == true
                ? currentStage!.description
                : plan?.description.isNotEmpty == true
                ? plan!.description
                : _t(context, '建立更稳定的应对机制', 'Build a steadier coping rhythm'),
          ),
          const SizedBox(height: 12),
          _SummaryLine(
            label: _t(context, '今日任务', 'Daily progress'),
            value: totalCount == 0
                ? _t(context, '暂无任务', 'No tasks')
                : '$completedCount / $totalCount',
          ),
        ],
      ),
    );
  }

  TreatmentStage? _currentStage(TreatmentPlan? plan) {
    if (plan == null || plan.stages.isEmpty) {
      return null;
    }
    return plan.stages.firstWhere(
      (stage) => stage.status == 1,
      orElse: () => plan.stages.first,
    );
  }

  String _planRange(TreatmentPlan? plan, DateTime selectedDate) {
    if (plan == null) {
      return DateFormat('yyyy-MM-dd').format(selectedDate);
    }
    final start = plan.startDate.trim();
    final end = plan.endDate.trim();
    if (start.isEmpty && end.isEmpty) {
      return DateFormat('yyyy-MM-dd').format(selectedDate);
    }
    if (start.isEmpty) {
      return end;
    }
    if (end.isEmpty) {
      return start;
    }
    return '$start - $end';
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFDDE8FF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekSwitcher extends StatelessWidget {
  const _WeekSwitcher({
    required this.selectedDate,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  final DateTime selectedDate;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanPalette.of(context);
    final title = DateFormat('yyyy-MM').format(selectedDate);

    return Row(
      children: [
        _MiniIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: onPreviousWeek,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _MiniIconButton(icon: Icons.chevron_right_rounded, onTap: onNextWeek),
      ],
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanPalette.of(context);
    return Material(
      color: palette.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: palette.secondaryText),
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selectedDate, required this.onSelected});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final first = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    final days = List.generate(7, (index) => first.add(Duration(days: index)));

    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _DayCell(
                date: day,
                selected: _sameDay(day, selectedDate),
                onTap: () => onSelected(day),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanPalette.of(context);
    final label = _weekdayLabel(context, date);

    return Material(
      color: selected ? const Color(0xFF2483F0) : palette.cardBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : palette.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${date.day}',
                style: TextStyle(
                  color: selected ? Colors.white : palette.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskScheduleCard extends StatelessWidget {
  const _TaskScheduleCard({
    required this.task,
    required this.onStatusChanged,
    required this.onOpen,
  });

  final DailyTask task;
  final VoidCallback onStatusChanged;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanPalette.of(context);
    final priority = _taskPriority(context, task);
    final doneColor = task.isDone
        ? const Color(0xFFB7E4A7)
        : const Color(0xFFE8EEF9);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              task.description,
              style: TextStyle(
                color: palette.bodyText,
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.softBackground,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _TaskMetaRow(
                        label: _t(context, '优先级', 'Priority'),
                        value: priority.$1,
                        valueColor: priority.$2,
                      ),
                      const SizedBox(height: 12),
                      _TaskMetaRow(
                        label: _t(context, '来源', 'Source'),
                        value: _taskSource(context, task.source),
                      ),
                      const SizedBox(height: 12),
                      _TaskMetaRow(
                        label: _t(context, '时间', 'Time'),
                        value: _taskTimeRange(task),
                      ),
                      const SizedBox(height: 12),
                      _TaskMetaRow(
                        label: _t(context, '分数', 'Points'),
                        value: '${task.pointsReward}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: doneColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    task.isDone
                        ? Icons.check_rounded
                        : task.isSkipped
                        ? Icons.skip_next_rounded
                        : Icons.schedule_rounded,
                    size: 46,
                    color: task.isDone
                        ? const Color(0xFF75BE62)
                        : const Color(0xFF5A81DA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  task.completedTime.isNotEmpty
                      ? _t(
                          context,
                          '已完成于 ${task.completedTime}',
                          'Completed at ${task.completedTime}',
                        )
                      : _t(
                          context,
                          '提醒时间 ${_taskTimeRange(task)}',
                          'Reminder ${_taskTimeRange(task)}',
                        ),
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!task.isDone) ...[
                TextButton(
                  onPressed: onStatusChanged,
                  child: Text(context.l10n.planTaskComplete),
                ),
                FilledButton.tonal(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    foregroundColor: const Color(0xFF5A81DA),
                  ),
                  child: Text(_t(context, '前往', 'Open')),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskMetaRow extends StatelessWidget {
  const _TaskMetaRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanPalette.of(context);
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? palette.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AssessmentInsightCard extends StatelessWidget {
  const _AssessmentInsightCard({required this.result});

  final AssessmentResult result;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.assessmentTitle,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AssessmentChip(
                label: _t(
                  context,
                  '等级 ${result.resultLevel}',
                  'Level ${result.resultLevel}',
                ),
              ),
              _AssessmentChip(
                label: '${result.achievedScore}/${result.totalScore}',
              ),
              if (result.assessedAt.isNotEmpty)
                _AssessmentChip(label: result.assessedAt),
            ],
          ),
          if (result.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              result.suggestions,
              style: TextStyle(
                color: palette.bodyText,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssessmentChip extends StatelessWidget {
  const _AssessmentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5A81DA),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanPalette.of(context);
    return Text(
      title,
      style: TextStyle(
        color: palette.primaryText,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLoadingCard extends StatelessWidget {
  const _SummaryLoadingCard({this.height = 172});

  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = _PlanPalette.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

(String, Color) _taskPriority(BuildContext context, DailyTask task) {
  if (task.taskType == 'checkin') {
    return (_t(context, '关键', 'Key'), const Color(0xFFFF5B61));
  }
  if (task.taskType == 'assessment') {
    return (_t(context, '一般', 'Normal'), const Color(0xFF5A81DA));
  }
  if (task.taskType == 'material') {
    return (_t(context, '学习', 'Learn'), const Color(0xFF7CBB5B));
  }
  return (_t(context, '常规', 'Routine'), const Color(0xFF5A81DA));
}

String _taskSource(BuildContext context, String source) {
  return switch (source) {
    'chat' || 'doctor' || 'ai' => _t(context, 'AI 心理医生', 'AI doctor'),
    'assessment' => _t(context, '评估量表', 'Assessment'),
    'material' => _t(context, '教育素材', 'Material'),
    _ => _t(context, '治疗计划', 'Treatment plan'),
  };
}

String _taskTimeRange(DailyTask task) {
  final start = task.startTime.trim();
  final end = task.endTime.trim();
  if (start.isEmpty && end.isEmpty) {
    return '--';
  }
  if (start.isEmpty) {
    return end;
  }
  if (end.isEmpty) {
    return start;
  }
  return '$start-$end';
}

String _weekdayLabel(BuildContext context, DateTime date) {
  const zh = ['日', '一', '二', '三', '四', '五', '六'];
  const en = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final index = date.weekday % 7;
  return Localizations.localeOf(context).languageCode == 'zh'
      ? zh[index]
      : en[index];
}

bool _sameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _firstText(List<Object?> values, {String fallback = ''}) {
  for (final value in values) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty && text != 'null') {
      return text;
    }
  }
  return fallback;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _PlanPalette {
  const _PlanPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softBackground,
    required this.avatarBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.bodyText,
  });

  factory _PlanPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _PlanPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      softBackground: scheme.surfaceContainerLow,
      avatarBackground: isDark
          ? scheme.primaryContainer.withValues(alpha: 0.28)
          : const Color(0xFFF8E3DB),
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
          : const Color(0xFF7D828A),
      bodyText: isDark
          ? scheme.onSurface.withValues(alpha: 0.84)
          : const Color(0xFF50545D),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softBackground;
  final Color avatarBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color bodyText;
}
