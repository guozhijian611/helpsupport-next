import 'package:flutter/material.dart';
import 'package:helpsupport_app/core/cache/cached_remote_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/member_text_localizer.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/ui/app_tab_shell_metrics.dart';
import '../../auth/application/auth_controller.dart';
import '../../plan/data/plan_models.dart';
import '../application/doctor_controller.dart';
import '../data/doctor_models.dart';

class DoctorPlanScreen extends ConsumerStatefulWidget {
  const DoctorPlanScreen({
    super.key,
    this.initialMemberId = 0,
    this.detailMode = false,
  });

  final int initialMemberId;
  final bool detailMode;

  @override
  ConsumerState<DoctorPlanScreen> createState() => _DoctorPlanScreenState();
}

class _DoctorPlanScreenState extends ConsumerState<DoctorPlanScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedMemberId = 0;
  final Map<int, DoctorPatient> _patientOverrides = {};

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
    final metrics = AppTabShellMetrics.of(context);
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
    final allTasks = _selectedMemberId > 0
        ? ref.watch(
            doctorDailyTasksProvider(
              DoctorDailyTasksQuery(memberId: _selectedMemberId),
            ),
          )
        : const AsyncValue<PlanPage<DailyTask>>.data(
            PlanPage(list: [], total: 0, page: 1, pageSize: 100),
          );

    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: ColoredBox(
        color: palette.pageBackground,
        child: SafeArea(
          top: true,
          bottom: false,
          child: RefreshIndicator(
            color: palette.brandPrimary,
            onRefresh: () async {
              ref.invalidate(doctorPatientsProvider(patientsQuery));
              if (_selectedMemberId > 0) {
                ref.invalidate(doctorDailyTasksProvider);
              }
              await ref.read(doctorPatientsProvider(patientsQuery).future);
            },
            child: ListView(
              padding: metrics
                  .edgeInsets(22, widget.detailMode ? 12 : 18, 22, 0)
                  .copyWith(
                    bottom: metrics.floatingTabBarInset(
                      context,
                      extraSpacing: 32,
                    ),
                  ),
              children: [
                widget.detailMode
                    ? _DoctorPlanDetailHeader(onBack: _handleBack)
                    : _DoctorPlanHeader(name: nickname),
                SizedBox(height: metrics.size(20)),
                patients.when(
                  data: (page) {
                    final patient = _resolveSelectedPatient(page.list);
                    if (patient == null) {
                      return _DoctorPlanEmptyState(
                        onOpenPatients: () => context.push('/doctor/patients'),
                      );
                    }
                    final month = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PatientSelectorCard(
                          patient: patient,
                          onTap: () => _selectPatient(page.list),
                        ),
                        SizedBox(height: metrics.size(18)),
                        plans.when(
                          data: (items) {
                            final taskItems =
                                tasks.asData?.value.list ?? const [];
                            final allTaskItems =
                                allTasks.asData?.value.list ?? const [];
                            final activePlan = _activePlan(items);
                            final currentMonthTasks = _currentMonthTasks(
                              allTaskItems,
                              DateTime(_selectedDate.year, _selectedDate.month),
                            );
                            final completedMonthTasks = currentMonthTasks
                                .where((task) => task.isDone)
                                .length;
                            final pendingMonthTasks = currentMonthTasks
                                .where((task) => !task.isDone)
                                .length;
                            final monthPlanValue = pendingMonthTasks > 0
                                ? _t(
                                    context,
                                    '待完成 $pendingMonthTasks 项',
                                    '$pendingMonthTasks pending',
                                  )
                                : activePlan?.title ??
                                      _t(context, '暂无任务', 'No tasks');
                            final summaryGrid = _PatientRecoverySummaryGrid(
                              monthPlanValue: monthPlanValue,
                              triggerValue: patient.triggerTags.isEmpty
                                  ? _t(context, '待补充', 'To complete')
                                  : patient.triggerTags.take(2).join(' '),
                              recoveryValue: patient.recoveryGoal.isEmpty
                                  ? _t(
                                      context,
                                      '已完成 $completedMonthTasks 项',
                                      '$completedMonthTasks finished',
                                    )
                                  : patient.recoveryGoal,
                              onPlanTap: () => _openTreatmentPlan(
                                patient.memberId,
                                activePlan?.id ?? 0,
                              ),
                              onTriggerTap: () => _editTriggerTags(patient),
                              onRecoveryTap: () => _editRecoveryGoal(patient),
                            );
                            if (activePlan == null) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  summaryGrid,
                                  const SizedBox(height: 18),
                                  _PlanOverviewCard(
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
                                    onTap: () =>
                                        _openTreatmentPlan(patient.memberId),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                summaryGrid,
                                const SizedBox(height: 18),
                                _ActivePlanSchedule(
                                  activePlan: activePlan,
                                  currentStage: _currentStage(activePlan),
                                  taskItems: taskItems,
                                  tasks: tasks,
                                  month: month,
                                  selectedDate: _selectedDate,
                                  onPreviousMonth: () => setState(
                                    () => _selectedDate = DateTime(
                                      month.year,
                                      month.month - 1,
                                      _selectedDate.day.clamp(1, 28),
                                    ),
                                  ),
                                  onNextMonth: () => setState(
                                    () => _selectedDate = DateTime(
                                      month.year,
                                      month.month + 1,
                                      _selectedDate.day.clamp(1, 28),
                                    ),
                                  ),
                                  onSelectedDate: (date) =>
                                      setState(() => _selectedDate = date),
                                  onOpenTreatmentPlan: () => _openTreatmentPlan(
                                    patient.memberId,
                                    activePlan.id,
                                  ),
                                ),
                              ],
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
                      ],
                    );
                  },
                  error: (error, _) => _TaskEmptyCard(text: error.toString()),
                  loading: () => const _DoctorTaskSkeleton(),
                ),
              ],
            ),
          ),
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
      return _patientOverrides[patients.first.memberId] ?? patients.first;
    }
    final patient =
        patients.cast<DoctorPatient?>().firstWhere(
          (item) => item?.memberId == _selectedMemberId,
          orElse: () => patients.first,
        ) ??
        patients.first;
    return _patientOverrides[patient.memberId] ?? patient;
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

  Future<void> _editRecoveryGoal(DoctorPatient patient) async {
    final nextValue = await _showDoctorPlanTextInputSheet(
      context: context,
      title: _t(context, '编辑康复目标', 'Edit recovery goal'),
      initialValue: patient.recoveryGoal,
      hintText: _t(context, '请输入康复目标', 'Enter recovery goal'),
      maxLines: 4,
    );
    if (!mounted ||
        nextValue == null ||
        nextValue.trim() == patient.recoveryGoal.trim()) {
      return;
    }
    await _savePatientProfile(
      patient,
      recoveryGoal: nextValue.trim(),
      successMessage: _t(context, '康复目标已更新', 'Recovery goal updated'),
    );
  }

  Future<void> _editTriggerTags(DoctorPatient patient) async {
    final nextValue = await _showDoctorPlanTextInputSheet(
      context: context,
      title: _t(context, '编辑重点触发', 'Edit key triggers'),
      initialValue: patient.triggerTags.join(', '),
      hintText: _t(context, '多个触发因素请用逗号分隔', 'Separate triggers with commas'),
      maxLines: 4,
    );
    if (!mounted || nextValue == null) {
      return;
    }
    final tags = nextValue
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (tags.join(',') == patient.triggerTags.join(',')) {
      return;
    }
    await _savePatientProfile(
      patient,
      triggerTags: tags,
      successMessage: _t(context, '重点触发已更新', 'Key triggers updated'),
    );
  }

  Future<void> _savePatientProfile(
    DoctorPatient patient, {
    String? recoveryGoal,
    List<String>? triggerTags,
    required String successMessage,
  }) async {
    try {
      final updated = await ref
          .read(doctorRepositoryProvider)
          .savePatientProfile(
            memberId: patient.memberId,
            recoveryGoal: recoveryGoal,
            triggerTags: triggerTags,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _patientOverrides[patient.memberId] = updated;
      });
      ref.invalidate(doctorPatientsProvider);
      context.showCenteredNotice(successMessage);
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/doctor/patients');
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
          child: Icon(Icons.person_rounded, color: palette.brandPrimary),
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

class _DoctorPlanDetailHeader extends StatelessWidget {
  const _DoctorPlanDetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _DoctorPlanHeaderButton(
              tooltip: _t(context, '返回', 'Back'),
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
            ),
          ),
          Text(
            _t(context, '患者详情', 'Patient detail'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _DoctorPlanHeaderButton(
              tooltip: _t(context, '消息', 'Messages'),
              icon: Icons.notifications_none_rounded,
              onTap: () => context.push('/me/messages'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorPlanHeaderButton extends StatelessWidget {
  const _DoctorPlanHeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.cardBackground,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: palette.primaryText, size: 22),
          ),
        ),
      ),
    );
  }
}

class _PatientRecoverySummaryGrid extends StatelessWidget {
  const _PatientRecoverySummaryGrid({
    required this.monthPlanValue,
    required this.triggerValue,
    required this.recoveryValue,
    required this.onPlanTap,
    required this.onTriggerTap,
    required this.onRecoveryTap,
  });

  final String monthPlanValue;
  final String triggerValue;
  final String recoveryValue;
  final VoidCallback onPlanTap;
  final VoidCallback onTriggerTap;
  final VoidCallback onRecoveryTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PatientRecoverySummaryCard(
            title: _t(context, '本月计划', 'Monthly plan'),
            value: monthPlanValue,
            icon: Icons.graphic_eq_rounded,
            color: const Color(0xFFFF9585),
            onTap: onPlanTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PatientRecoverySummaryCard(
            title: _t(context, '重点触发', 'Key triggers'),
            value: triggerValue,
            icon: Icons.hub_rounded,
            color: const Color(0xFFFFAE4D),
            onTap: onTriggerTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PatientRecoverySummaryCard(
            title: _t(context, '康复目标', 'Recovery goal'),
            value: recoveryValue,
            icon: Icons.track_changes_rounded,
            color: const Color(0xFF5A81DA),
            onTap: onRecoveryTap,
          ),
        ),
      ],
    );
  }
}

class _PatientRecoverySummaryCard extends StatelessWidget {
  const _PatientRecoverySummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    final metrics = AppTabShellMetrics.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          height: metrics.size(104),
          padding: metrics.edgeInsets(12, 14, 10, 14),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: metrics.size(14),
                    backgroundColor: color,
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: metrics.size(18),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 15,
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

class _PatientSelectorCard extends ConsumerWidget {
  const _PatientSelectorCard({required this.patient, required this.onTap});

  final DoctorPatient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _DoctorPlanPalette.of(context);
    final avatarUrl = ref.watch(apiClientProvider).resolveUrl(patient.avatar);
    final bindTime = _formatDateTimeLabel(patient.bindTime);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: avatarUrl.isNotEmpty
                        ? CachedRemoteImage(
                            avatarUrl,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const _DoctorPlanAvatarPlaceholder(),
                          )
                        : const _DoctorPlanAvatarPlaceholder(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _PatientInfoChip(label: 'ID ${patient.memberId}'),
                            _PatientInfoChip(
                              label: _patientAgeLabel(context, patient),
                            ),
                            _PatientInfoChip(label: patient.genderLabel),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.outline,
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (bindTime.isNotEmpty)
                _PatientDetailLine(
                  icon: Icons.link_rounded,
                  label: _t(context, '绑定时间', 'Bound'),
                  text: _t(context, '绑定于 $bindTime', 'Bound on $bindTime'),
                  color: palette.infoColor,
                ),
              if (bindTime.isEmpty)
                _PatientDetailLine(
                  icon: Icons.account_circle_rounded,
                  label: _t(context, '患者信息', 'Patient info'),
                  text: _t(
                    context,
                    '患者基础信息已同步，可点击切换患者。',
                    'Patient profile synced. Tap to switch patients.',
                  ),
                  color: palette.infoColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorPlanAvatarPlaceholder extends StatelessWidget {
  const _DoctorPlanAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Container(
      width: 58,
      height: 58,
      color: palette.avatarBackground,
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded, color: palette.brandPrimary),
    );
  }
}

class _PatientInfoChip extends StatelessWidget {
  const _PatientInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: palette.secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

class _PatientDetailLine extends StatelessWidget {
  const _PatientDetailLine({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              style: TextStyle(
                color: palette.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
              children: [
                TextSpan(
                  text: '$label：',
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanActionLabel extends StatelessWidget {
  const _PlanActionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PlanActionIcon extends StatelessWidget {
  const _PlanActionIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.edit_note_rounded, size: 22);
  }
}

class _PlanActionButton extends StatelessWidget {
  const _PlanActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: palette.brandPrimary,
        side: BorderSide(color: palette.brandPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PlanActionIcon(),
          const SizedBox(width: 8),
          Flexible(child: _PlanActionLabel(label: label)),
        ],
      ),
    );
  }
}

class _PlanSectionTitle extends StatelessWidget {
  const _PlanSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Text(
      title,
      style: TextStyle(
        color: palette.primaryText,
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PlanCardTitle extends StatelessWidget {
  const _PlanCardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Text(
      text,
      style: TextStyle(
        color: palette.primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
    );
  }
}

class _PlanCardBody extends StatelessWidget {
  const _PlanCardBody(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Text(
      text,
      style: TextStyle(color: palette.mutedText, fontSize: 14, height: 1.65),
    );
  }
}

class _PlanCardContainer extends StatelessWidget {
  const _PlanCardContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(26),
      ),
      child: child,
    );
  }
}

class _PlanOverviewContent extends StatelessWidget {
  const _PlanOverviewContent({
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
    return _PlanCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanCardTitle(title),
          const SizedBox(height: 10),
          _PlanCardBody(subtitle),
          const SizedBox(height: 16),
          _PlanActionButton(label: actionLabel, onTap: onTap),
        ],
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
    return _PlanOverviewContent(
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onTap: onTap,
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

class _ActivePlanSchedule extends StatelessWidget {
  const _ActivePlanSchedule({
    required this.activePlan,
    required this.currentStage,
    required this.taskItems,
    required this.tasks,
    required this.month,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectedDate,
    required this.onOpenTreatmentPlan,
  });

  final TreatmentPlan activePlan;
  final TreatmentStage? currentStage;
  final List<DailyTask> taskItems;
  final AsyncValue<PlanPage<DailyTask>> tasks;
  final DateTime month;
  final DateTime selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectedDate;
  final VoidCallback onOpenTreatmentPlan;

  @override
  Widget build(BuildContext context) {
    final completedCount = taskItems.where((task) => task.isDone).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlanOverviewCard(
          title: activePlan.title,
          subtitle: [
            if (activePlan.startDate.trim().isNotEmpty ||
                activePlan.endDate.trim().isNotEmpty)
              '${_formatDateLabel(activePlan.startDate)} - ${_formatDateLabel(activePlan.endDate)}',
            if (currentStage?.description.trim().isNotEmpty == true)
              currentStage!.description,
            _t(
              context,
              '关键任务 $completedCount/${taskItems.length}',
              'Key tasks $completedCount/${taskItems.length}',
            ),
          ].join('\n'),
          actionLabel: _t(context, '配置治疗计划', 'Configure plan'),
          onTap: onOpenTreatmentPlan,
        ),
        const SizedBox(height: 18),
        _MonthNavigator(
          month: month,
          onPrevious: onPreviousMonth,
          onNext: onNextMonth,
        ),
        const SizedBox(height: 14),
        _MonthCalendar(selectedDate: selectedDate, onSelected: onSelectedDate),
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
                onTap: () => context.push('/doctor/assessment-scales'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _PlanSectionTitle(title: _t(context, '当日患者任务', 'Patient tasks')),
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
          error: (error, _) => _TaskEmptyCard(text: error.toString()),
          loading: () => const _DoctorTaskSkeleton(),
        ),
      ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
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

String _formatDateTimeLabel(String value) {
  final text = value.trim();
  if (text.isEmpty || text == '0' || text == 'null') {
    return '';
  }
  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    return text;
  }
  return DateFormat('yyyy-MM-dd').format(parsed);
}

List<DailyTask> _currentMonthTasks(List<DailyTask> tasks, DateTime month) {
  final prefix =
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
  return tasks.where((task) => task.taskDate.startsWith(prefix)).toList();
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

String _patientAgeLabel(BuildContext context, DoctorPatient patient) {
  if (patient.ageLabel == '--') {
    return _t(context, '年龄未知', 'Age unknown');
  }
  return _t(context, '${patient.ageLabel}岁', 'Age ${patient.ageLabel}');
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

Future<String?> _showDoctorPlanTextInputSheet({
  required BuildContext context,
  required String title,
  required String initialValue,
  required String hintText,
  int maxLines = 1,
}) {
  final palette = _DoctorPlanPalette.of(context);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: palette.pageBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    showDragHandle: true,
    builder: (sheetContext) => _DoctorPlanTextInputSheet(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      maxLines: maxLines,
    ),
  );
}

class _DoctorPlanTextInputSheet extends StatefulWidget {
  const _DoctorPlanTextInputSheet({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.maxLines,
  });

  final String title;
  final String initialValue;
  final String hintText;
  final int maxLines;

  @override
  State<_DoctorPlanTextInputSheet> createState() =>
      _DoctorPlanTextInputSheetState();
}

class _DoctorPlanTextInputSheetState extends State<_DoctorPlanTextInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close([String? value]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorPlanPalette.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              widget.title,
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 1,
            maxLines: widget.maxLines,
            textInputAction: widget.maxLines == 1
                ? TextInputAction.done
                : TextInputAction.newline,
            decoration: InputDecoration(hintText: widget.hintText),
            onSubmitted: widget.maxLines == 1
                ? (value) => _close(value.trim())
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _close(),
                  child: Text(_t(context, '取消', 'Cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _close(_controller.text.trim()),
                  child: Text(_t(context, '保存', 'Save')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
    required this.brandPrimary,
    required this.infoColor,
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
      brandPrimary: scheme.primary,
      infoColor: isDark ? scheme.secondary : const Color(0xFF5A81DA),
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
  final Color brandPrimary;
  final Color infoColor;
}
