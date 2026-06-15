import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/centered_notice.dart';
import '../../plan/data/plan_models.dart';
import '../application/doctor_controller.dart';
import '../data/doctor_models.dart';
import 'doctor_task_editor_screen.dart';
import 'doctor_treatment_stage_screen.dart';

class DoctorTreatmentPlanScreen extends ConsumerStatefulWidget {
  const DoctorTreatmentPlanScreen({
    super.key,
    this.initialMemberId = 0,
    this.initialPlanId = 0,
  });

  final int initialMemberId;
  final int initialPlanId;

  @override
  ConsumerState<DoctorTreatmentPlanScreen> createState() =>
      _DoctorTreatmentPlanScreenState();
}

class _DoctorTreatmentPlanScreenState
    extends ConsumerState<DoctorTreatmentPlanScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  int _selectedMemberId = 0;
  int _selectedPlanId = 0;
  int _status = 1;
  DateTime? _startDate;
  DateTime? _endDate;
  int _hydratedMemberId = -1;
  int _hydratedPlanId = -1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedMemberId = widget.initialMemberId;
    _selectedPlanId = widget.initialPlanId;
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsQuery = const DoctorPatientsQuery(status: 1, pageSize: 100);
    final patients = ref.watch(doctorPatientsProvider(patientsQuery));
    final plansQuery = _selectedMemberId > 0
        ? DoctorPatientPlansQuery(memberId: _selectedMemberId)
        : null;
    final plans = plansQuery == null
        ? const AsyncValue<List<TreatmentPlan>>.data([])
        : ref.watch(doctorPatientPlansProvider(plansQuery));
    final tasks = _selectedMemberId > 0 && _selectedPlanId > 0
        ? ref.watch(
            doctorDailyTasksProvider(
              DoctorDailyTasksQuery(
                memberId: _selectedMemberId,
                planId: _selectedPlanId,
              ),
            ),
          )
        : const AsyncValue<PlanPage<DailyTask>>.data(
            PlanPage(list: [], total: 0, page: 1, pageSize: 100),
          );

    if (plansQuery != null) {
      ref.listen<AsyncValue<List<TreatmentPlan>>>(
        doctorPatientPlansProvider(plansQuery),
        (_, next) {
          next.whenData(_syncPlans);
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: Text(_t(context, '配置治疗计划', 'Configure treatment plan')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(doctorPatientsProvider(patientsQuery));
            if (plansQuery != null) {
              ref.invalidate(doctorPatientPlansProvider(plansQuery));
            }
            ref.invalidate(doctorDailyTasksProvider);
            await ref.read(doctorPatientsProvider(patientsQuery).future);
            if (plansQuery != null) {
              await ref.read(doctorPatientPlansProvider(plansQuery).future);
            }
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              patients.when(
                data: (page) => _SelectorCard(
                  label: _t(context, '患者选择', 'Patient'),
                  value:
                      _selectedPatient(page.list)?.displayName ??
                      _t(context, '请选择患者', 'Select patient'),
                  onTap: () => _selectPatient(page.list),
                ),
                error: (error, _) => _InlineCard(
                  title: _t(context, '患者列表加载失败', 'Failed to load patients'),
                  subtitle: error.toString(),
                ),
                loading: () => const _LoadingCard(height: 88),
              ),
              const SizedBox(height: 16),
              if (_selectedMemberId > 0)
                plans.when(
                  data: (items) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (items.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _t(context, '已有计划', 'Existing plans'),
                                style: const TextStyle(
                                  color: Color(0xFF303236),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _createBlankPlan,
                              child: Text(_t(context, '新建', 'New')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final plan in items)
                              ChoiceChip(
                                label: Text(plan.title),
                                selected: plan.id == _selectedPlanId,
                                onSelected: (_) => _selectPlan(plan),
                                selectedColor: const Color(0xFFEAF0FF),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: plan.id == _selectedPlanId
                                      ? const Color(0xFF5A81DA)
                                      : const Color(0xFF7D828A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      _PlanFormCard(
                        titleController: _titleController,
                        descriptionController: _descriptionController,
                        startDate: _startDate,
                        endDate: _endDate,
                        statusLabel: _planStatusLabel(context, _status),
                        onPickStart: () => _pickDate(isStart: true),
                        onPickEnd: () => _pickDate(isStart: false),
                        onPickStatus: _pickStatus,
                      ),
                    ],
                  ),
                  error: (error, _) => _InlineCard(
                    title: _t(context, '治疗计划加载失败', 'Failed to load plans'),
                    subtitle: error.toString(),
                  ),
                  loading: () => const _LoadingCard(height: 260),
                ),
              if (_selectedMemberId > 0) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _t(context, '阶段设置', 'Stages'),
                        style: const TextStyle(
                          color: Color(0xFF303236),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _addStage,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(_t(context, '添加阶段', 'Add stage')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                plans.when(
                  data: (items) {
                    final plan = _activePlan(items);
                    if (plan == null) {
                      return _InlineCard(
                        title: _t(context, '先保存治疗计划', 'Save the plan first'),
                        subtitle: _t(
                          context,
                          '保存计划后再继续配置阶段和任务。',
                          'Save the plan before adding stages and tasks.',
                        ),
                      );
                    }
                    if (plan.stages.isEmpty) {
                      return _InlineCard(
                        title: _t(context, '还没有阶段', 'No stages yet'),
                        subtitle: _t(
                          context,
                          '先添加阶段，再给每个阶段配置关键任务。',
                          'Add a stage before configuring key tasks.',
                        ),
                      );
                    }
                    final groupedTasks = _groupTasksByStage(
                      tasks.asData?.value.list ?? const [],
                    );
                    return Column(
                      children: [
                        for (final stage in plan.stages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _StageCard(
                              stage: stage,
                              taskCount: groupedTasks[stage.id]?.length ?? 0,
                              onEdit: () => _editStage(stage),
                              onAddTask: () => _addTask(stage),
                            ),
                          ),
                      ],
                    );
                  },
                  error: (error, _) => _InlineCard(
                    title: _t(context, '阶段读取失败', 'Failed to load stages'),
                    subtitle: error.toString(),
                  ),
                  loading: () => const _LoadingCard(height: 200),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _savePlan,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF5A81DA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(_t(context, '完成', 'Done')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DoctorPatient? _selectedPatient(List<DoctorPatient> patients) {
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
    if (_selectedPlanId > 0) {
      for (final plan in plans) {
        if (plan.id == _selectedPlanId) {
          return plan;
        }
      }
    }
    for (final plan in plans) {
      if (plan.status == 1) {
        return plan;
      }
    }
    return plans.first;
  }

  Map<int, List<DailyTask>> _groupTasksByStage(List<DailyTask> tasks) {
    final result = <int, List<DailyTask>>{};
    for (final task in tasks) {
      result.putIfAbsent(task.stageId, () => <DailyTask>[]).add(task);
    }
    return result;
  }

  void _syncPlans(List<TreatmentPlan> plans) {
    if (_hydratedMemberId == _selectedMemberId &&
        _hydratedPlanId == _selectedPlanId &&
        _selectedPlanId > 0) {
      return;
    }
    final plan = _activePlan(plans);
    if (plan == null) {
      if (_hydratedMemberId != _selectedMemberId || _hydratedPlanId != 0) {
        _selectedPlanId = 0;
        _hydratedMemberId = _selectedMemberId;
        _hydratedPlanId = 0;
        _titleController.clear();
        _descriptionController.clear();
        _startDate = null;
        _endDate = null;
        _status = 1;
      }
      return;
    }
    _selectPlan(plan, hydrateOnly: true);
  }

  void _selectPlan(TreatmentPlan plan, {bool hydrateOnly = false}) {
    _selectedPlanId = plan.id;
    _hydratedPlanId = plan.id;
    _hydratedMemberId = _selectedMemberId;
    _titleController.text = plan.title;
    _descriptionController.text = plan.description;
    _startDate = _parseDate(plan.startDate);
    _endDate = _parseDate(plan.endDate);
    _status = plan.status == 0 ? 1 : plan.status;
    if (!hydrateOnly && mounted) {
      setState(() {});
    }
  }

  void _createBlankPlan() {
    setState(() {
      _selectedPlanId = 0;
      _hydratedPlanId = 0;
      _hydratedMemberId = _selectedMemberId;
      _titleController.clear();
      _descriptionController.clear();
      _startDate = null;
      _endDate = null;
      _status = 1;
    });
  }

  Future<void> _selectPatient(List<DoctorPatient> patients) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                style: const TextStyle(
                  color: Color(0xFF303236),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              for (final patient in patients)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  tileColor: patient.memberId == _selectedMemberId
                      ? const Color(0xFFFFF1EE)
                      : const Color(0xFFF7F8FB),
                  title: Text(patient.displayName),
                  subtitle: Text(
                    '${_t(context, '年龄', 'Age')} ${patient.ageLabel} · ${_t(context, '性别', 'Gender')} ${patient.genderLabel}',
                  ),
                  onTap: () => Navigator.of(context).pop(patient.memberId),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedMemberId = picked;
        _selectedPlanId = 0;
        _hydratedPlanId = -1;
        _hydratedMemberId = -1;
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickStatus() async {
    final value = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            children: [
              Text(
                _t(context, '计划状态', 'Plan status'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF303236),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              for (final item in const [1, 2, 3])
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  tileColor: item == _status
                      ? const Color(0xFFEAF0FF)
                      : const Color(0xFFF7F8FB),
                  title: Text(_planStatusLabel(context, item)),
                  onTap: () => Navigator.of(context).pop(item),
                ),
            ],
          ),
        ),
      ),
    );
    if (value != null && mounted) {
      setState(() => _status = value);
    }
  }

  Future<int> _ensurePlanSaved() async {
    if (_selectedMemberId <= 0) {
      throw StateError(_t(context, '请先选择患者', 'Please select a patient'));
    }
    if (_titleController.text.trim().isEmpty) {
      throw StateError(_t(context, '请先填写计划标题', 'Please enter a plan title'));
    }
    final plan = await ref
        .read(doctorRepositoryProvider)
        .saveTreatmentPlan(
          memberId: _selectedMemberId,
          id: _selectedPlanId,
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: _formatNullableDate(_startDate),
          endDate: _formatNullableDate(_endDate),
          status: _status,
        );
    _selectedPlanId = plan.id;
    _hydratedPlanId = plan.id;
    _hydratedMemberId = _selectedMemberId;
    final query = DoctorPatientPlansQuery(memberId: _selectedMemberId);
    ref.invalidate(doctorPatientPlansProvider(query));
    await ref.read(doctorPatientPlansProvider(query).future);
    return plan.id;
  }

  Future<void> _savePlan() async {
    if (_selectedMemberId <= 0) {
      context.showCenteredNotice(
        _t(context, '请先选择患者', 'Please select a patient'),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      context.showCenteredNotice(
        _t(context, '请先填写计划标题', 'Please enter a plan title'),
      );
      return;
    }
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      context.showCenteredNotice(
        _t(
          context,
          '结束日期不能早于开始日期',
          'End date cannot be earlier than start date',
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _ensurePlanSaved();
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        _t(context, '治疗计划已保存', 'Treatment plan saved'),
      );
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _addStage() async {
    try {
      final planId = await _ensurePlanSaved();
      if (!mounted) {
        return;
      }
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => DoctorTreatmentStageScreen(
            memberId: _selectedMemberId,
            planId: planId,
          ),
        ),
      );
      if (changed == true) {
        final query = DoctorPatientPlansQuery(memberId: _selectedMemberId);
        ref.invalidate(doctorPatientPlansProvider(query));
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  Future<void> _editStage(TreatmentStage stage) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DoctorTreatmentStageScreen(
          memberId: _selectedMemberId,
          planId: _selectedPlanId,
          stage: stage,
        ),
      ),
    );
    if (changed == true && mounted) {
      final query = DoctorPatientPlansQuery(memberId: _selectedMemberId);
      ref.invalidate(doctorPatientPlansProvider(query));
    }
  }

  Future<void> _addTask(TreatmentStage stage) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DoctorTaskEditorScreen(
          memberId: _selectedMemberId,
          planId: _selectedPlanId,
          stageId: stage.id,
          initialDate: _formatNullableDate(_startDate) == ''
              ? DateFormat('yyyy-MM-dd').format(DateTime.now())
              : _formatNullableDate(_startDate),
        ),
      ),
    );
    if (changed == true && mounted) {
      ref.invalidate(doctorDailyTasksProvider);
    }
  }
}

class _SelectorCard extends StatelessWidget {
  const _SelectorCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        title: Text(
          label,
          style: const TextStyle(color: Color(0xFF9AA0A8), fontSize: 16),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF303236),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC8CDD6)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _PlanFormCard extends StatelessWidget {
  const _PlanFormCard({
    required this.titleController,
    required this.descriptionController,
    required this.startDate,
    required this.endDate,
    required this.statusLabel,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onPickStatus,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final DateTime? startDate;
  final DateTime? endDate;
  final String statusLabel;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onPickStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _PlanTextFieldRow(
            label: _t(context, '计划标题', 'Plan title'),
            controller: titleController,
            hintText: _t(
              context,
              '例如：阶段二应对训练',
              'Example: Stage 2 response training',
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EBF1)),
          _PlanTextFieldRow(
            label: _t(context, '计划说明', 'Description'),
            controller: descriptionController,
            hintText: _t(
              context,
              '补充本次治疗计划目标和说明',
              'Describe the goal of this treatment plan',
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const Divider(height: 1, color: Color(0xFFE8EBF1)),
          _PlanActionRow(
            label: _t(context, '开始日期', 'Start date'),
            value: _formatNullableDate(startDate),
            onTap: onPickStart,
          ),
          const Divider(height: 1, color: Color(0xFFE8EBF1)),
          _PlanActionRow(
            label: _t(context, '结束日期', 'End date'),
            value: _formatNullableDate(endDate),
            onTap: onPickEnd,
          ),
          const Divider(height: 1, color: Color(0xFFE8EBF1)),
          _PlanActionRow(
            label: _t(context, '计划状态', 'Plan status'),
            value: statusLabel,
            onTap: onPickStatus,
          ),
        ],
      ),
    );
  }
}

class _PlanTextFieldRow extends StatelessWidget {
  const _PlanTextFieldRow({
    required this.label,
    required this.controller,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        crossAxisAlignment: minLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF9AA0A8), fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: minLines,
              maxLines: maxLines,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                border: InputBorder.none,
              ),
              style: const TextStyle(
                color: Color(0xFF303236),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanActionRow extends StatelessWidget {
  const _PlanActionRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF9AA0A8), fontSize: 16),
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value.isEmpty ? '--' : value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF303236),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC8CDD6)),
          ],
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.taskCount,
    required this.onEdit,
    required this.onAddTask,
  });

  final TreatmentStage stage;
  final int taskCount;
  final VoidCallback onEdit;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stage.stageName,
                  style: const TextStyle(
                    color: Color(0xFF303236),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text(_t(context, '编辑阶段', 'Edit')),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatDateString(stage.startDate)} - ${_formatDateString(stage.endDate)}',
            style: const TextStyle(
              color: Color(0xFF7D828A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (stage.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              stage.description,
              style: const TextStyle(
                color: Color(0xFF6D7480),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _stageStatusLabel(context, stage.status),
                  style: const TextStyle(
                    color: Color(0xFF5A81DA),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _t(context, '任务 $taskCount', 'Tasks $taskCount'),
                style: const TextStyle(
                  color: Color(0xFF9AA0A8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: onAddTask,
                icon: const Icon(Icons.add_task_rounded),
                label: Text(_t(context, '添加任务', 'Add task')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineCard extends StatelessWidget {
  const _InlineCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7D828A),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

String _planStatusLabel(BuildContext context, int value) {
  return switch (value) {
    2 => _t(context, '已完成', 'Completed'),
    3 => _t(context, '已终止', 'Stopped'),
    _ => _t(context, '进行中', 'In progress'),
  };
}

String _stageStatusLabel(BuildContext context, int value) {
  return switch (value) {
    1 => _t(context, '进行中', 'In progress'),
    2 => _t(context, '已完成', 'Completed'),
    _ => _t(context, '待开始', 'Pending'),
  };
}

DateTime? _parseDate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return DateTime.tryParse(trimmed);
}

String _formatNullableDate(DateTime? value) {
  if (value == null) {
    return '';
  }
  return DateFormat('yyyy-MM-dd').format(value);
}

String _formatDateString(String value) {
  final parsed = DateTime.tryParse(value.trim());
  if (parsed == null) {
    return value;
  }
  return DateFormat('yyyy-MM-dd').format(parsed);
}
