import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/member_text_localizer.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../auth/application/auth_controller.dart';
import '../../plan/data/plan_models.dart';
import '../application/doctor_controller.dart';
import '../data/doctor_models.dart';

class DoctorPlanScreen extends ConsumerStatefulWidget {
  const DoctorPlanScreen({super.key, this.initialMemberId = 0});

  final int initialMemberId;

  @override
  ConsumerState<DoctorPlanScreen> createState() => _DoctorPlanScreenState();
}

class _DoctorPlanScreenState extends ConsumerState<DoctorPlanScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedMemberId = 0;

  @override
  void initState() {
    super.initState();
    _selectedMemberId = widget.initialMemberId;
  }

  @override
  void didUpdateWidget(covariant DoctorPlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMemberId > 0 &&
        widget.initialMemberId != oldWidget.initialMemberId &&
        widget.initialMemberId != _selectedMemberId) {
      _selectedMemberId = widget.initialMemberId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final nickname = _firstText([
      session?.profile['nickname'],
      session?.member['nickname'],
      session?.member['username'],
    ], fallback: 'Doctor');
    final patientsQuery = const DoctorPatientsQuery(status: 1, pageSize: 100);
    final patients = ref.watch(doctorPatientsProvider(patientsQuery));
    final plans = _selectedMemberId > 0
        ? ref.watch(
            doctorPatientPlansProvider(
              DoctorPatientPlansQuery(memberId: _selectedMemberId),
            ),
          )
        : const AsyncValue<List<TreatmentPlan>>.data([]);
    final tasks = _selectedMemberId > 0
        ? ref.watch(
            doctorDailyTasksProvider(
              DoctorDailyTasksQuery(
                memberId: _selectedMemberId,
                date: _dateKey(_selectedDate),
              ),
            ),
          )
        : const AsyncValue<PlanPage<DailyTask>>.data(
            PlanPage(list: [], total: 0, page: 1, pageSize: 100),
          );

    return ColoredBox(
      color: palette.pageBackground,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(doctorPatientsProvider(patientsQuery));
          if (_selectedMemberId > 0) {
            ref.invalidate(doctorDailyTasksProvider);
          }
          await ref.read(doctorPatientsProvider(patientsQuery).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          children: [
            _DoctorPlanHeader(name: nickname),
            const SizedBox(height: 20),
            patients.when(
              data: (page) {
                final patient = _resolveSelectedPatient(page.list);
                if (patient == null) {
                  return _DoctorPlanEmptyState(
                    onOpenPatients: () => context.push('/doctor/patients'),
                  );
                }
                final month = DateTime(_selectedDate.year, _selectedDate.month);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PatientSelectorCard(
                      patient: patient,
                      onTap: () => _selectPatient(page.list),
                    ),
                    const SizedBox(height: 18),
                    plans.when(
                      data: (items) {
                        final taskItems = tasks.asData?.value.list ?? const [];
                        final activePlan = _activePlan(items);
                        if (activePlan == null) {
                          return _PlanOverviewCard(
                            title: _t(
                              context,
                              '还没有治疗计划',
                              'No treatment plan yet',
                            ),
                            subtitle: _t(
                              context,
                              '先为当前患者配置计划、阶段和关键任务。',
                              'Create a plan, stages, and key tasks for this patient.',
                            ),
                            actionLabel: _t(
                              context,
                              '配置治疗计划',
                              'Configure plan',
                            ),
                            onTap: () => _openTreatmentPlan(patient.memberId),
                          );
                        }
                        final completedCount = taskItems
                            .where((task) => task.isDone)
                            .length;
                        return _PlanOverviewCard(
                          title: activePlan.title,
                          subtitle: [
                            if (activePlan.startDate.trim().isNotEmpty ||
                                activePlan.endDate.trim().isNotEmpty)
                              '${_formatDateLabel(activePlan.startDate)} - ${_formatDateLabel(activePlan.endDate)}',
                            if (_currentStage(
                                  activePlan,
                                )?.description.trim().isNotEmpty ==
                                true)
                              _currentStage(activePlan)!.description,
                            _t(
                              context,
                              '关键任务 $completedCount/${taskItems.length}',
                              'Key tasks $completedCount/${taskItems.length}',
                            ),
                          ].join('\n'),
                          actionLabel: _t(context, '配置治疗计划', 'Configure plan'),
                          onTap: () => _openTreatmentPlan(
                            patient.memberId,
                            activePlan.id,
                          ),
                        );
                      },
                      error: (error, _) => _PlanOverviewCard(
                        title: _t(context, '治疗计划读取失败', 'Plan load failed'),
                        subtitle: error.toString(),
                        actionLabel: _t(context, '重新配置', 'Configure again'),
                        onTap: () => _openTreatmentPlan(patient.memberId),
                      ),
                      loading: () => const _PlanOverviewSkeleton(),
                    ),
                    const SizedBox(height: 18),
                    _MonthNavigator(
                      month: month,
                      onPrevious: () => setState(
                        () => _selectedDate = DateTime(
                          month.year,
                          month.month - 1,
                          _selectedDate.day.clamp(1, 28),
                        ),
                      ),
                      onNext: () => setState(
                        () => _selectedDate = DateTime(
                          month.year,
                          month.month + 1,
                          _selectedDate.day.clamp(1, 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _MonthCalendar(
                      selectedDate: _selectedDate,
                      onSelected: (date) =>
                          setState(() => _selectedDate = date),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _ShortcutCard(
                            title: _t(context, '任务模板', 'Templates'),
                            icon: Icons.library_books_rounded,
                            color: const Color(0xFF986FF5),
                            onTap: () => context.push('/doctor/task-templates'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ShortcutCard(
                            title: _t(context, '评估量表', 'Scales'),
                            icon: Icons.fact_check_rounded,
                            color: const Color(0xFF7BC96F),
                            onTap: () =>
                                context.push('/doctor/assessment-scales'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _t(context, '当日患者任务', 'Patient tasks'),
                      style: const TextStyle(
                        color: Color(0xFF303236),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    tasks.when(
                      data: (taskPage) => taskPage.list.isEmpty
                          ? _TaskEmptyCard(
                              text: _t(
                                context,
                                '当前日期没有任务安排，可切换日期查看其它任务。',
                                'No tasks are scheduled on this date.',
                              ),
                            )
                          : Column(
                              children: [
                                for (final task in taskPage.list)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _DoctorTaskCard(task: task),
                                  ),
                              ],
                            ),
                      error: (error, _) =>
                          _TaskEmptyCard(text: error.toString()),
                      loading: () => const _DoctorTaskSkeleton(),
                    ),
                  ],
                );
              },
              error: (error, _) => _TaskEmptyCard(text: error.toString()),
              loading: () => const _DoctorTaskSkeleton(),
            ),
          ],
        ),
      ),
    );
  }

  DoctorPatient? _resolveSelectedPatient(List<DoctorPatient> patients) {
    if (patients.isEmpty) {
      return null;
    }
    if (_selectedMemberId <= 0) {
      _selectedMemberId = patients.first.memberId;
      return patients.first;
    }
    return patients.cast<DoctorPatient?>().firstWhere(
          (item) => item?.memberId == _selectedMemberId,
          orElse: () => patients.first,
        ) ??
        patients.first;
  }

  TreatmentPlan? _activePlan(List<TreatmentPlan> plans) {
    if (plans.isEmpty) {
      return null;
    }
    for (final plan in plans) {
      if (plan.status == 1) {
        return plan;
      }
    }
    return plans.first;
  }

  TreatmentStage? _currentStage(TreatmentPlan plan) {
    if (plan.stages.isEmpty) {
      return null;
    }
    for (final stage in plan.stages) {
      if (stage.status == 1) {
        return stage;
      }
    }
    return plan.stages.first;
  }

  Future<void> _selectPatient(List<DoctorPatient> patients) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final palette = _DoctorPlanPalette.of(context);
        return Container(
          decoration: BoxDecoration(
            color: palette.sheetBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
              children: [
                Text(
                  _t(context, '选择患者', 'Select patient'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                for (final patient in patients)
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: patient.memberId == _selectedMemberId
                          ? palette.selectedSoftBackground
                          : palette.softBackground,
                      title: Text(patient.displayName),
                      subtitle: Text(
                        '${_t(context, '年龄', 'Age')} ${patient.ageLabel} · ${_t(context, '性别', 'Gender')} ${patient.genderLabel}',
                      ),
                      onTap: () => Navigator.of(context).pop(patient.memberId),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedMemberId = picked);
    }
  }

  Future<void> _openTreatmentPlan(int memberId, [int planId = 0]) async {
    final changed = await context.push<bool>(
      Uri(
        path: '/doctor/treatment-plan',
        queryParameters: {
          'memberId': '$memberId',
          if (planId > 0) 'planId': '$planId',
        },
      ).toString(),
    );
    if (changed == true) {
      ref.invalidate(doctorPatientPlansProvider);
      ref.invalidate(doctorDailyTasksProvider);
    }
  }
}

class _DoctorPlanHeader extends StatelessWidget {
  const _DoctorPlanHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: palette.avatarBackground,
          child: const Icon(Icons.person_rounded, color: Color(0xFF5A81DA)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizedGreeting(context),
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
          onPressed: () => context.push('/me/messages'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _PatientSelectorCard extends StatelessWidget {
  const _PatientSelectorCard({required this.patient, required this.onTap});

  final DoctorPatient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  patient.displayName,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.outline,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanOverviewCard extends StatelessWidget {
  const _PlanOverviewCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 14,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(actionLabel),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: const Color(0xFF5A81DA),
              side: const BorderSide(color: Color(0xFF5A81DA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanOverviewSkeleton extends StatelessWidget {
  const _PlanOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Container(
      height: 176,
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(26),
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Row(
      children: [
        _CalendarButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('yyyy-MM').format(month),
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        _CalendarButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _CalendarButton extends StatelessWidget {
  const _CalendarButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: palette.cardBackground,
          border: Border.all(color: palette.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: palette.secondaryText),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.selectedDate, required this.onSelected});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
    final firstDayOffset = monthStart.weekday % 7;
    final gridStart = monthStart.subtract(Duration(days: firstDayOffset));
    final weeks = List<List<DateTime>>.generate(5, (weekIndex) {
      return List<DateTime>.generate(
        7,
        (dayIndex) => gridStart.add(Duration(days: weekIndex * 7 + dayIndex)),
        growable: false,
      );
    }, growable: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final label in const ['日', '一', '二', '三', '四', '五', '六'])
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: palette.secondaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final week in weeks)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: palette.outline)),
              ),
              child: Row(
                children: [
                  for (final day in week)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onSelected(day),
                        child: Container(
                          height: 70,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _dateKey(day) == _dateKey(selectedDate)
                                ? const Color(0xFFDCE9FB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: day.month == selectedDate.month
                                  ? palette.primaryText
                                  : palette.outline,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
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
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorTaskCard extends StatelessWidget {
  const _DoctorTaskCard({required this.task});

  final DailyTask task;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    final accent = task.isDone
        ? const Color(0xFF7BC96F)
        : const Color(0xFFFF9585);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                task.isDone
                    ? _t(context, '已完成', 'Done')
                    : _t(context, '待处理', 'Pending'),
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.description.isEmpty
                ? _t(
                    context,
                    '该任务已进入患者日程，可在完成后回到列表查看结果。',
                    'This task has been added to the patient schedule.',
                  )
                : task.description,
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TaskPill(label: task.taskType.isEmpty ? 'daily' : task.taskType),
              if (task.startTime.isNotEmpty || task.endTime.isNotEmpty)
                _TaskPill(label: '${task.startTime}-${task.endTime}'),
              _TaskPill(
                label: _t(
                  context,
                  '积分 ${task.pointsReward}',
                  'Score ${task.pointsReward}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskPill extends StatelessWidget {
  const _TaskPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.pillText,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DoctorPlanEmptyState extends StatelessWidget {
  const _DoctorPlanEmptyState({required this.onOpenPatients});

  final VoidCallback onOpenPatients;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(Icons.groups_rounded, size: 38, color: Color(0xFF5A81DA)),
          const SizedBox(height: 14),
          Text(
            _t(context, '还没有患者', 'No patients yet'),
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _t(
              context,
              '先绑定患者，再查看该患者的任务日历和治疗安排。',
              'Bind a patient first to view the task calendar.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onOpenPatients,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9585),
            ),
            child: Text(_t(context, '前往患者列表', 'Open patients')),
          ),
        ],
      ),
    );
  }
}

class _TaskEmptyCard extends StatelessWidget {
  const _TaskEmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: TextStyle(color: palette.mutedText, fontSize: 14, height: 1.6),
      ),
    );
  }
}

class _DoctorTaskSkeleton extends StatelessWidget {
  const _DoctorTaskSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Column(
      children: List<Widget>.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _formatDateLabel(String value) {
  final parsed = DateTime.tryParse(value.trim());
  if (parsed == null) {
    final text = value.trim();
    return text.isEmpty ? '--' : text;
  }
  return DateFormat('yyyy-MM-dd').format(parsed);
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

class _DoctorPlanPalette {
  const _DoctorPlanPalette({
    required this.pageBackground,
    required this.sheetBackground,
    required this.cardBackground,
    required this.softBackground,
    required this.selectedSoftBackground,
    required this.avatarBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.outline,
    required this.pillText,
  });

  factory _DoctorPlanPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _DoctorPlanPalette(
      pageBackground: scheme.surface,
      sheetBackground: scheme.surfaceContainerLowest,
      cardBackground: scheme.surfaceContainerLowest,
      softBackground: scheme.surfaceContainerLow,
      selectedSoftBackground: isDark
          ? scheme.primaryContainer.withValues(alpha: 0.42)
          : const Color(0xFFFFF1EE),
      avatarBackground: isDark
          ? scheme.primaryContainer.withValues(alpha: 0.32)
          : const Color(0xFFF0F4FF),
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
          : const Color(0xFF7D828A),
      outline: scheme.outlineVariant,
      pillText: isDark ? scheme.primary : const Color(0xFF5A81DA),
    );
  }

  final Color pageBackground;
  final Color sheetBackground;
  final Color cardBackground;
  final Color softBackground;
  final Color selectedSoftBackground;
  final Color avatarBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color outline;
  final Color pillText;
}
