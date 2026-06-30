import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _keyTasksExpanded = true;
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
    final palette = _DoctorTreatmentPlanPalette.of(context);
    final patientsQuery = const DoctorPatientsQuery(status: 1, pageSize: 100);
    final patients = ref.watch(doctorPatientsProvider(patientsQuery));
    _selectDefaultPatientWhenReady(patients.asData?.value.list);
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
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
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
                  data: (items) {
                    final activePlan = _activePlan(items);
                    final taskList = _sortTasks(
                      tasks.asData?.value.list ?? const <DailyTask>[],
                    );
                    final groupedTasks = _groupTasksByStage(taskList);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (items.isNotEmpty) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _t(context, '已有计划', 'Existing plans'),
                                  style: TextStyle(
                                    color: palette.primaryText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: activePlan == null || _saving
                                    ? null
                                    : () => _deletePlan(activePlan),
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: Text(_t(context, '删除', 'Delete')),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF8D7F),
                                ),
                              ),
                              TextButton(
                                onPressed: _createBlankPlan,
                                child: Text(_t(context, '新建', 'New')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 72,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                final plan = items[index];
                                final selected = plan.id == _selectedPlanId;
                                return _PlanSummaryPill(
                                  plan: plan,
                                  selected: selected,
                                  onTap: () => _selectPlan(plan),
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemCount: items.length,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _KeyTaskPanel(
                          expanded: _keyTasksExpanded,
                          tasks: taskList,
                          onToggle: () => setState(
                            () => _keyTasksExpanded = !_keyTasksExpanded,
                          ),
                          onAddTask: () => _addTaskFromKeySection(activePlan),
                          onTaskTap: _showTaskSummary,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _t(context, '阶段配置', 'Stages'),
                                style: TextStyle(
                                  color: palette.primaryText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _saving ? null : _addStage,
                              icon: const Icon(Icons.add_rounded),
                              label: Text(_t(context, '阶段', 'Stage')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (activePlan != null)
                          Column(
                            children: [
                              for (
                                var index = 0;
                                index < activePlan.stages.length;
                                index += 1
                              ) ...[
                                _TreatmentStageCard(
                                  order: index + 1,
                                  stage: activePlan.stages[index],
                                  tasks:
                                      groupedTasks[activePlan
                                          .stages[index]
                                          .id] ??
                                      const <DailyTask>[],
                                  onEdit: () =>
                                      _editStage(activePlan.stages[index]),
                                  onAddTask: () =>
                                      _addTask(activePlan.stages[index]),
                                  onTaskTap: _showTaskSummary,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                      ],
                    );
                  },
                  error: (error, _) => _InlineCard(
                    title: _t(context, '治疗计划加载失败', 'Failed to load plans'),
                    subtitle: error.toString(),
                  ),
                  loading: () => const _LoadingCard(height: 260),
                ),
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
                child: Text(_t(context, '完成配置', 'Finish setup')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDefaultPatientWhenReady(List<DoctorPatient>? patients) {
    if (_selectedMemberId > 0 || patients == null || patients.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedMemberId > 0) {
        return;
      }
      setState(() {
        _selectedMemberId = patients.first.memberId;
        _hydratedMemberId = -1;
        _hydratedPlanId = -1;
      });
    });
  }

  DoctorPatient? _selectedPatient(List<DoctorPatient> patients) {
    if (patients.isEmpty) {
      return null;
    }
    if (_selectedMemberId <= 0) {
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

  List<DailyTask> _sortTasks(List<DailyTask> tasks) {
    final sorted = tasks.toList(growable: false);
    sorted.sort((left, right) {
      final dateCompare = left.taskDate.compareTo(right.taskDate);
      if (dateCompare != 0) {
        return dateCompare;
      }
      final startCompare = left.startTime.compareTo(right.startTime);
      if (startCompare != 0) {
        return startCompare;
      }
      return left.id.compareTo(right.id);
    });
    return sorted;
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
      builder: (context) {
        final palette = _DoctorTreatmentPlanPalette.of(context);
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
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_t(context, '年龄', 'Age')} ${patient.ageLabel} · ${_t(context, '性别', 'Gender')} ${patient.genderLabel}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _patientPlanSummary(context, patient),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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
      builder: (context) {
        final palette = _DoctorTreatmentPlanPalette.of(context);
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
                  _t(context, '计划状态', 'Plan status'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in const [1, 2, 3])
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: item == _status
                          ? palette.selectedChipBackground
                          : palette.softBackground,
                      title: Text(_planStatusLabel(context, item)),
                      onTap: () => Navigator.of(context).pop(item),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (value != null && mounted) {
      setState(() => _status = value);
    }
  }

  Future<int> _ensurePlanSaved() async {
    if (_selectedMemberId <= 0) {
      throw StateError(_t(context, '请先选择患者', 'Please select a patient'));
    }
    final title = _effectivePlanTitle();
    final plan = await ref
        .read(doctorRepositoryProvider)
        .saveTreatmentPlan(
          memberId: _selectedMemberId,
          id: _selectedPlanId,
          title: title,
          description: _descriptionController.text,
          startDate: _formatNullableDate(_startDate),
          endDate: _formatNullableDate(_endDate),
          status: _status,
        );
    _titleController.text = plan.title.isEmpty ? title : plan.title;
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

  Future<void> _deletePlan(TreatmentPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t(context, '删除治疗计划', 'Delete treatment plan')),
        content: Text(
          _t(
            context,
            '删除后该计划下的阶段和任务也会移除，确定继续吗？',
            'Stages and tasks under this plan will also be removed. Continue?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t(context, '取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8D7F),
            ),
            child: Text(_t(context, '删除', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(doctorRepositoryProvider)
          .deleteTreatmentPlan(memberId: _selectedMemberId, id: plan.id);
      if (!mounted) {
        return;
      }
      _selectedPlanId = 0;
      _hydratedPlanId = -1;
      _hydratedMemberId = -1;
      final query = DoctorPatientPlansQuery(memberId: _selectedMemberId);
      ref.invalidate(doctorPatientPlansProvider(query));
      ref.invalidate(doctorDailyTasksProvider);
      await ref.read(doctorPatientPlansProvider(query).future);
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        _t(context, '治疗计划已删除', 'Treatment plan deleted'),
      );
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
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

  Future<void> _addTaskFromKeySection(TreatmentPlan? plan) async {
    if (plan == null || plan.id <= 0) {
      context.showCenteredNotice(
        _t(context, '请先添加阶段', 'Please add a stage first'),
      );
      return;
    }
    if (plan.stages.isEmpty) {
      context.showCenteredNotice(
        _t(context, '请先添加阶段', 'Please add a stage first'),
      );
      return;
    }
    if (plan.stages.length == 1) {
      await _addTask(plan.stages.first);
      return;
    }
    final pickedStageId = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final palette = _DoctorTreatmentPlanPalette.of(context);
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
                  _t(context, '选择任务所属阶段', 'Choose a stage'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                for (final stage in plan.stages)
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: palette.softBackground,
                      title: Text(stage.stageName),
                      subtitle: Text(
                        '${_formatDateString(stage.startDate)} - ${_formatDateString(stage.endDate)}',
                      ),
                      onTap: () => Navigator.of(context).pop(stage.id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (pickedStageId == null || !mounted) {
      return;
    }
    final pickedStage = plan.stages.cast<TreatmentStage?>().firstWhere(
      (item) => item?.id == pickedStageId,
      orElse: () => null,
    );
    if (pickedStage != null) {
      await _addTask(pickedStage);
    }
  }

  void _showTaskSummary(DailyTask task) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final palette = _DoctorTreatmentPlanPalette.of(context);
        return Container(
          decoration: BoxDecoration(
            color: palette.sheetBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                Text(
                  task.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _TaskSummaryRow(
                  label: _t(context, '日期', 'Date'),
                  value: task.taskDate,
                ),
                _TaskSummaryRow(
                  label: _t(context, '时间', 'Time'),
                  value: [
                    task.startTime.trim(),
                    task.endTime.trim(),
                  ].where((item) => item.isNotEmpty).join(' - '),
                ),
                _TaskSummaryRow(
                  label: _t(context, '任务类型', 'Type'),
                  value: task.taskType,
                ),
                _TaskSummaryRow(
                  label: _t(context, '奖励积分', 'Reward'),
                  value: '${task.pointsReward}',
                ),
                if (task.description.trim().isNotEmpty)
                  _TaskSummaryRow(
                    label: _t(context, '说明', 'Description'),
                    value: task.description,
                    multiline: true,
                  ),
                if (task.attachments.isNotEmpty)
                  _TaskSummaryRow(
                    label: _t(context, '附件', 'Attachments'),
                    value: task.attachments.join('、'),
                    multiline: true,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _effectivePlanTitle() {
    final trimmed = _titleController.text.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    final patientName = _selectedPatientName();
    final generic = _t(context, '治疗计划', 'Treatment plan');
    if (patientName.isEmpty) {
      return generic;
    }
    return '$patientName $generic';
  }

  String _selectedPatientName() {
    final state = ref.read(
      doctorPatientsProvider(
        const DoctorPatientsQuery(status: 1, pageSize: 100),
      ),
    );
    final patients = state.asData?.value.list ?? const <DoctorPatient>[];
    for (final patient in patients) {
      if (patient.memberId == _selectedMemberId) {
        return patient.displayName;
      }
    }
    return '';
  }
}

class _KeyTaskPanel extends StatelessWidget {
  const _KeyTaskPanel({
    required this.expanded,
    required this.tasks,
    required this.onToggle,
    required this.onAddTask,
    required this.onTaskTap,
  });

  final bool expanded;
  final List<DailyTask> tasks;
  final VoidCallback onToggle;
  final VoidCallback onAddTask;
  final ValueChanged<DailyTask> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTreatmentPlanPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggle,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _t(context, '关键任务', 'Key tasks'),
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.chevron_right_rounded,
                  color: palette.outline,
                  size: 28,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 16),
            if (tasks.isNotEmpty) ...[
              for (final task in tasks.take(3)) ...[
                _KeyTaskTile(task: task, onTap: () => onTaskTap(task)),
                const SizedBox(height: 12),
              ],
            ],
            OutlinedButton(
              onPressed: onAddTask,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(72),
                side: const BorderSide(color: Color(0xFF5A81DA), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                _t(context, '+ 添加任务', '+ Add task'),
                style: const TextStyle(
                  color: Color(0xFF5A81DA),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanSummaryPill extends StatelessWidget {
  const _PlanSummaryPill({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final TreatmentPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTreatmentPlanPalette.of(context);
    final stageSummary = _stageSummary(context);
    return SizedBox(
      width: 184,
      child: Material(
        color: selected
            ? palette.selectedChipBackground
            : palette.cardBackground,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? const Color(0xFFFF8D7F)
                      : palette.secondaryText,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? palette.selectedChipText
                              : palette.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        stageSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? palette.selectedChipText.withValues(alpha: 0.78)
                              : palette.secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stageSummary(BuildContext context) {
    if (plan.stages.isEmpty) {
      return _t(context, '未配置阶段', 'No stages');
    }
    final names = plan.stages
        .take(2)
        .map((stage) => stage.stageName.trim())
        .where((name) => name.isNotEmpty)
        .join(' / ');
    final count = plan.stages.length;
    if (names.isEmpty) {
      return _t(context, '$count 个阶段', '$count stages');
    }
    return _t(context, '$count 个阶段 · $names', '$count stages · $names');
  }
}

class _KeyTaskTile extends StatelessWidget {
  const _KeyTaskTile({required this.task, required this.onTap});

  final DailyTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTreatmentPlanPalette.of(context);
    final trailing = task.isDone
        ? Text(
            _t(context, '已完成', 'Done'),
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          )
        : Icon(
            task.taskType == 'assessment'
                ? Icons.edit_note_rounded
                : Icons.chevron_right_rounded,
            color: const Color(0xFF5A81DA),
            size: 28,
          );

    return Material(
      color: palette.softBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      task.taskDate,
                      style: TextStyle(
                        color: palette.mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _TreatmentStageCard extends StatelessWidget {
  const _TreatmentStageCard({
    required this.order,
    required this.stage,
    required this.tasks,
    required this.onEdit,
    required this.onAddTask,
    required this.onTaskTap,
  });

  final int order;
  final TreatmentStage stage;
  final List<DailyTask> tasks;
  final VoidCallback onEdit;
  final VoidCallback onAddTask;
  final ValueChanged<DailyTask> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTreatmentPlanPalette.of(context);
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
              Expanded(
                child: Text(
                  _t(context, '阶段$order', 'Stage $order'),
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.chevron_right_rounded, color: palette.outline),
              ),
            ],
          ),
          Divider(height: 24, color: palette.outline),
          _StageDetailRow(
            label: _t(context, '阶段名称', 'Stage name'),
            value: stage.stageName,
            onTap: onEdit,
          ),
          _StageDetailRow(
            label: _t(context, '起始日期', 'Start date'),
            value: _formatDateString(stage.startDate),
            onTap: onEdit,
          ),
          _StageDetailRow(
            label: _t(context, '结束日期', 'End date'),
            value: _formatDateString(stage.endDate),
            onTap: onEdit,
          ),
          _StageDetailRow(
            label: _t(context, '阶段目标', 'Stage goal'),
            value: stage.description.trim().isEmpty
                ? _t(context, '待补充', 'To be filled')
                : stage.description,
            onTap: onEdit,
          ),
          const SizedBox(height: 12),
          Text(
            _t(context, '任务设置', 'Task settings'),
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _StageTaskWrap(
            tasks: tasks,
            onAddTask: onAddTask,
            onTaskTap: onTaskTap,
          ),
        ],
      ),
    );
  }
}

class _StageDetailRow extends StatelessWidget {
  const _StageDetailRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTreatmentPlanPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 94,
              child: Text(
                label,
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: palette.outline),
          ],
        ),
      ),
    );
  }
}

class _StageTaskWrap extends StatelessWidget {
  const _StageTaskWrap({
    required this.tasks,
    required this.onAddTask,
    required this.onTaskTap,
  });

  final List<DailyTask> tasks;
  final VoidCallback onAddTask;
  final ValueChanged<DailyTask> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final visibleTasks = tasks.take(2).toList(growable: false);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var index = 0; index < visibleTasks.length; index += 1)
          _StageTaskTile(
            task: visibleTasks[index],
            color: index.isEven
                ? const Color(0xFFA7BDF2)
                : const Color(0xFFF5C0B4),
            onTap: () => onTaskTap(visibleTasks[index]),
          ),
        _AddTaskTile(onTap: onAddTask),
      ],
    );
  }
}

class _StageTaskTile extends StatelessWidget {
  const _StageTaskTile({
    required this.task,
    required this.color,
    required this.onTap,
  });

  final DailyTask task;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 132,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  task.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                if (task.taskDate.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    task.taskDate,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTaskTile extends StatelessWidget {
  const _AddTaskTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTreatmentPlanPalette.of(context);
    return SizedBox(
      width: 100,
      height: 132,
      child: Material(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: Icon(
              Icons.add_rounded,
              color: palette.secondaryText,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskSummaryRow extends StatelessWidget {
  const _TaskSummaryRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTreatmentPlanPalette.of(context);
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(
                color: palette.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
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
    final palette = _DoctorTreatmentPlanPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        title: Text(
          label,
          style: TextStyle(color: palette.secondaryText, fontSize: 16),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: palette.outline),
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
    final palette = _DoctorTreatmentPlanPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
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
          Divider(height: 1, color: palette.outline),
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
          Divider(height: 1, color: palette.outline),
          _PlanActionRow(
            label: _t(context, '开始日期', 'Start date'),
            value: _formatNullableDate(startDate),
            onTap: onPickStart,
          ),
          Divider(height: 1, color: palette.outline),
          _PlanActionRow(
            label: _t(context, '结束日期', 'End date'),
            value: _formatNullableDate(endDate),
            onTap: onPickEnd,
          ),
          Divider(height: 1, color: palette.outline),
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
    final palette = _DoctorTreatmentPlanPalette.of(context);
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
              style: TextStyle(color: palette.secondaryText, fontSize: 16),
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
                hintStyle: TextStyle(color: palette.mutedText),
              ),
              style: TextStyle(
                color: palette.primaryText,
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
    final palette = _DoctorTreatmentPlanPalette.of(context);
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
                style: TextStyle(color: palette.secondaryText, fontSize: 16),
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value.isEmpty ? '--' : value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: palette.outline),
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
    final palette = _DoctorTreatmentPlanPalette.of(context);
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
              Expanded(
                child: Text(
                  stage.stageName,
                  style: TextStyle(
                    color: palette.primaryText,
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
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (stage.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              stage.description,
              style: TextStyle(
                color: palette.secondaryText,
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
                  color: palette.selectedChipBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _stageStatusLabel(context, stage.status),
                  style: TextStyle(
                    color: palette.selectedChipText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _t(context, '任务 $taskCount', 'Tasks $taskCount'),
                style: TextStyle(
                  color: palette.secondaryText,
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
    final palette = _DoctorTreatmentPlanPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: palette.secondaryText,
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
    final palette = _DoctorTreatmentPlanPalette.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _DoctorTreatmentPlanPalette {
  const _DoctorTreatmentPlanPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.sheetBackground,
    required this.softBackground,
    required this.selectedSoftBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.outline,
    required this.selectedChipBackground,
    required this.selectedChipText,
  });

  factory _DoctorTreatmentPlanPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _DoctorTreatmentPlanPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      sheetBackground: scheme.surfaceContainerLowest,
      softBackground: scheme.surfaceContainerLow,
      selectedSoftBackground: isDark
          ? scheme.primaryContainer.withValues(alpha: 0.42)
          : const Color(0xFFFFF1EE),
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
          : const Color(0xFF7D828A),
      outline: scheme.outlineVariant,
      selectedChipBackground: isDark
          ? scheme.primaryContainer
          : const Color(0xFFEAF0FF),
      selectedChipText: isDark
          ? scheme.onPrimaryContainer
          : const Color(0xFF5A81DA),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color sheetBackground;
  final Color softBackground;
  final Color selectedSoftBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color outline;
  final Color selectedChipBackground;
  final Color selectedChipText;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

String _patientPlanSummary(BuildContext context, DoctorPatient patient) {
  if (patient.currentPlanId <= 0) {
    return _t(context, '暂无治疗计划', 'No treatment plan');
  }
  final stageName = patient.currentStageName.trim().isEmpty
      ? _t(context, '未配置阶段', 'No stage')
      : patient.currentStageName.trim();
  return _t(
    context,
    '当前阶段 $stageName · 任务 ${patient.currentStageDoneCount}/${patient.currentStageTaskCount}',
    'Stage $stageName · Tasks ${patient.currentStageDoneCount}/${patient.currentStageTaskCount}',
  );
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
