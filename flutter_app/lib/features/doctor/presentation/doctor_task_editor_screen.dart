import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/centered_notice.dart';
import '../../material/application/material_controller.dart';
import '../../material/data/material_models.dart';
import '../application/doctor_controller.dart';
import '../data/doctor_models.dart';

class DoctorTaskEditorScreen extends ConsumerStatefulWidget {
  const DoctorTaskEditorScreen({
    super.key,
    required this.memberId,
    required this.planId,
    required this.stageId,
    this.initialDate = '',
    this.initialTaskType = 'daily',
  });

  final int memberId;
  final int planId;
  final int stageId;
  final String initialDate;
  final String initialTaskType;

  @override
  ConsumerState<DoctorTaskEditorScreen> createState() =>
      _DoctorTaskEditorScreenState();
}

class _DoctorTaskEditorScreenState
    extends ConsumerState<DoctorTaskEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _rewardController;
  late final TextEditingController _feedbackPromptController;
  late DateTime _taskDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _taskType = 'daily';
  DoctorTaskTemplate? _selectedTaskTemplate;
  DoctorAssessmentScale? _selectedAssessmentScale;
  List<MaterialItem> _selectedLearningMaterials = const [];
  List<DailyTaskAttachment> _templateLearningMaterials = const [];
  bool _requiresFeedback = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _rewardController = TextEditingController(text: '20');
    _feedbackPromptController = TextEditingController();
    _taskDate = _parseDate(widget.initialDate) ?? DateTime.now();
    final normalizedTaskType = widget.initialTaskType.trim();
    if (normalizedTaskType.isNotEmpty) {
      _taskType = normalizedTaskType;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    _feedbackPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskEditorPalette.of(context);
    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(_t(context, '添加关键任务', 'Add key task')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            _EditorCard(
              child: Column(
                children: [
                  _EditorTextRow(
                    label: _t(context, '任务名称', 'Task name'),
                    controller: _titleController,
                    hintText: _t(
                      context,
                      '例如：填写评估量表',
                      'Example: Complete the assessment scale',
                    ),
                  ),
                  _editorDivider(context),
                  _EditorTextRow(
                    label: _t(context, '任务描述', 'Description'),
                    controller: _descriptionController,
                    hintText: _t(
                      context,
                      '描述任务的执行要求',
                      'Describe what needs to be done',
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  _editorDivider(context),
                  _EditorActionRow(
                    label: _t(context, '任务模板', 'Template'),
                    value:
                        _selectedTaskTemplate?.title ??
                        _t(context, '请选择', 'Select'),
                    onTap: _pickTaskTemplate,
                  ),
                  _editorDivider(context),
                  _EditorActionRow(
                    label: _t(context, '引用量表', 'Scale'),
                    value:
                        _selectedAssessmentScale?.title ??
                        _t(context, '请选择', 'Select'),
                    onTap: _pickAssessmentScale,
                  ),
                  _editorDivider(context),
                  _EditorActionRow(
                    label: _t(context, '任务类型', 'Task type'),
                    value: _taskTypeLabel(context, _taskType),
                    onTap: _pickTaskType,
                  ),
                  _editorDivider(context),
                  if (_taskType != 'assessment') ...[
                    _EditorSwitchRow(
                      label: _t(context, '患者反馈', 'Patient feedback'),
                      value: _requiresFeedback,
                      onChanged: (value) =>
                          setState(() => _requiresFeedback = value),
                    ),
                  ],
                  if (_taskType != 'assessment' && _requiresFeedback) ...[
                    _editorDivider(context),
                    _EditorTextRow(
                      label: _t(context, '反馈提示', 'Prompt'),
                      controller: _feedbackPromptController,
                      hintText: _t(
                        context,
                        '例如：写下今天的情绪、压力和身体感受',
                        'Example: Record mood, stress, and body feelings',
                      ),
                      minLines: 2,
                      maxLines: 3,
                    ),
                  ],
                  _editorDivider(context),
                  _EditorActionRow(
                    label: _t(context, '日期选择', 'Task date'),
                    value: DateFormat('yyyy-MM-dd').format(_taskDate),
                    onTap: _pickDate,
                  ),
                  _editorDivider(context),
                  _EditorActionRow(
                    label: _t(context, '开始时间', 'Start time'),
                    value: _formatTime(_startTime),
                    onTap: () => _pickTime(isStart: true),
                  ),
                  _editorDivider(context),
                  _EditorActionRow(
                    label: _t(context, '结束时间', 'End time'),
                    value: _formatTime(_endTime),
                    onTap: () => _pickTime(isStart: false),
                  ),
                  _editorDivider(context),
                  _EditorTextRow(
                    label: _t(context, '奖励分数', 'Reward score'),
                    controller: _rewardController,
                    hintText: '20',
                    keyboardType: TextInputType.number,
                  ),
                  if (_taskType == 'material') ...[
                    _editorDivider(context),
                    _EditorActionRow(
                      label: _t(context, '学习素材', 'Learning material'),
                      value: _learningMaterialSummary(
                        context,
                        _selectedLearningMaterials,
                        _templateLearningMaterials,
                      ),
                      onTap: _pickLearningMaterials,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
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
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _taskDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _taskDate = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 8, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 9, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _pickLearningMaterials() async {
    final selected = await showModalBottomSheet<List<MaterialItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LearningMaterialSelectionSheet(
        selectedItems: _selectedLearningMaterials,
        locale: Localizations.localeOf(context).toLanguageTag(),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedLearningMaterials = selected;
        _templateLearningMaterials = const [];
      });
    }
  }

  Future<void> _pickTaskTemplate() async {
    try {
      final templates = await ref
          .read(doctorRepositoryProvider)
          .fetchTaskTemplates(status: 1);
      if (!mounted) {
        return;
      }
      if (templates.isEmpty) {
        context.showCenteredNotice(
          _t(
            context,
            '还没有可用任务模板，请先去模板页创建',
            'No task templates available yet. Please create one first.',
          ),
        );
        return;
      }
      final selected = await showModalBottomSheet<DoctorTaskTemplate>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          final palette = _DoctorTaskEditorPalette.of(context);
          return Container(
            decoration: BoxDecoration(
              color: palette.sheetBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                children: [
                  Text(
                    _t(context, '任务模板', 'Task template'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final template in templates)
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        tileColor: _selectedTaskTemplate?.id == template.id
                            ? palette.selectedChipBackground
                            : palette.softBackground,
                        title: Text(template.title),
                        subtitle: Text(
                          [
                            _taskTypeLabel(context, template.taskType),
                            if (template.stage.trim().isNotEmpty)
                              template.stage,
                            if (template.rewardScore > 0)
                              _t(
                                context,
                                '${template.rewardScore} 分',
                                '${template.rewardScore} pts',
                              ),
                          ].join(' · '),
                        ),
                        onTap: () => Navigator.of(context).pop(template),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
      if (selected != null && mounted) {
        _applyTaskTemplate(selected);
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    }
  }

  void _applyTaskTemplate(DoctorTaskTemplate template) {
    setState(() {
      _selectedTaskTemplate = template;
      _titleController.text = template.title;
      _descriptionController.text = template.description;
      _taskType = template.taskType.trim().isEmpty
          ? 'daily'
          : template.taskType.trim();
      _startTime = _parseClockTime(template.startTime);
      _endTime = _parseClockTime(template.endTime);
      if (template.rewardScore > 0) {
        _rewardController.text = '${template.rewardScore}';
      }
      _selectedAssessmentScale = null;
      if (_taskType == 'assessment') {
        _requiresFeedback = false;
        _feedbackPromptController.clear();
      }
      if (_taskType != 'material') {
        _selectedLearningMaterials = const [];
        _templateLearningMaterials = const [];
      } else {
        _templateLearningMaterials = template.attachments;
      }
    });
  }

  Future<void> _pickTaskType() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final palette = _DoctorTaskEditorPalette.of(context);
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
                  _t(context, '任务类型', 'Task type'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in const [
                  'daily',
                  'assessment',
                  'material',
                  'checkin',
                ])
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: item == _taskType
                          ? palette.selectedChipBackground
                          : palette.softBackground,
                      title: Text(_taskTypeLabel(context, item)),
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
      setState(() {
        _taskType = value;
        if (value != 'assessment') {
          _selectedAssessmentScale = null;
        } else {
          _requiresFeedback = false;
          _feedbackPromptController.clear();
        }
        if (value != 'material') {
          _selectedLearningMaterials = const [];
          _templateLearningMaterials = const [];
        }
      });
    }
  }

  Future<void> _pickAssessmentScale() async {
    final scales = await ref
        .read(doctorRepositoryProvider)
        .fetchAssessmentScales(status: 'published');
    if (!mounted) {
      return;
    }
    if (scales.isEmpty) {
      context.showCenteredNotice(
        _t(
          context,
          '还没有已发布量表，请先去量表页创建并发布',
          'No published scales yet. Please create and publish one first.',
        ),
      );
      return;
    }
    final selected = await showModalBottomSheet<DoctorAssessmentScale>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final palette = _DoctorTaskEditorPalette.of(context);
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
                  _t(context, '量表选择', 'Assessment scale'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                for (final scale in scales)
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: _selectedAssessmentScale?.id == scale.id
                          ? palette.selectedChipBackground
                          : palette.softBackground,
                      title: Text(scale.title),
                      subtitle: Text(
                        _t(
                          context,
                          '${scale.questions.length} 题 · 总分 ${scale.totalScore}',
                          '${scale.questions.length} questions · ${scale.totalScore} points',
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(scale),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedAssessmentScale = selected;
        _selectedTaskTemplate = null;
        _taskType = 'assessment';
        _selectedLearningMaterials = const [];
        _templateLearningMaterials = const [];
        _requiresFeedback = false;
        _feedbackPromptController.clear();
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = selected.title;
        }
        if (_descriptionController.text.trim().isEmpty &&
            selected.description.trim().isNotEmpty) {
          _descriptionController.text = selected.description;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      context.showCenteredNotice(
        _t(context, '请先填写任务名称', 'Please enter a task name'),
      );
      return;
    }
    if (_taskType == 'assessment' &&
        _selectedAssessmentScale == null &&
        _selectedTaskTemplate == null) {
      context.showCenteredNotice(
        _t(context, '请先选择评估量表', 'Please choose an assessment scale'),
      );
      return;
    }
    if (_taskType == 'material' &&
        _selectedLearningMaterials.isEmpty &&
        _templateLearningMaterials.isEmpty) {
      context.showCenteredNotice(
        _t(context, '请先选择学习素材', 'Please choose learning material'),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final source = _selectedAssessmentScale != null
          ? 'assessment'
          : (_selectedTaskTemplate != null ? 'template' : 'doctor');
      final sourceId =
          _selectedAssessmentScale?.id ?? _selectedTaskTemplate?.id ?? '';
      await ref
          .read(doctorRepositoryProvider)
          .saveDailyTask(
            memberId: widget.memberId,
            planId: widget.planId,
            stageId: widget.stageId,
            taskDate: DateFormat('yyyy-MM-dd').format(_taskDate),
            startTime: _timeValue(_startTime),
            endTime: _timeValue(_endTime),
            title: _titleController.text,
            description: _descriptionController.text,
            taskType: _taskType,
            source: source,
            sourceId: sourceId,
            attachments: _taskType == 'material'
                ? _learningMaterialPayloads(
                    _selectedLearningMaterials,
                    _templateLearningMaterials,
                  )
                : const [],
            pointsReward: int.tryParse(_rewardController.text.trim()) ?? 20,
            requiresFeedback: _taskType != 'assessment' && _requiresFeedback,
            feedbackPrompt: _taskType != 'assessment'
                ? _feedbackPromptController.text
                : '',
          );
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(_t(context, '关键任务已保存', 'Task saved'));
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
}

class _LearningMaterialSelectionSheet extends ConsumerStatefulWidget {
  const _LearningMaterialSelectionSheet({
    required this.selectedItems,
    required this.locale,
  });

  final List<MaterialItem> selectedItems;
  final String locale;

  @override
  ConsumerState<_LearningMaterialSelectionSheet> createState() =>
      _LearningMaterialSelectionSheetState();
}

class _LearningMaterialSelectionSheetState
    extends ConsumerState<_LearningMaterialSelectionSheet> {
  late final TextEditingController _keywordController;
  late final Set<int> _selectedIds;
  late final Map<int, MaterialItem> _selectedItemsById;
  List<MaterialCategory> _categories = const [];
  List<MaterialItem> _items = const [];
  bool _loading = true;
  String _error = '';
  int _categoryId = 0;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController();
    _selectedIds = widget.selectedItems.map((item) => item.id).toSet();
    _selectedItemsById = {
      for (final item in widget.selectedItems) item.id: item,
    };
    _loadMaterials(includeCategories: true);
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials({bool includeCategories = false}) async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final repository = ref.read(materialRepositoryProvider);
      final categories = includeCategories
          ? await repository.fetchCategories(
              type: 'education',
              locale: widget.locale,
            )
          : _categories;
      final page = await repository.fetchMaterials(
        materialType: 'education',
        categoryId: _categoryId,
        keyword: _keywordController.text.trim(),
        locale: widget.locale,
        pageSize: 500,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = categories;
        _items = page.list;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _toggleMaterial(MaterialItem item) {
    setState(() {
      if (_selectedIds.contains(item.id)) {
        _selectedIds.remove(item.id);
        _selectedItemsById.remove(item.id);
      } else {
        _selectedIds.add(item.id);
        _selectedItemsById[item.id] = item;
      }
    });
  }

  void _selectCategory(int categoryId) {
    if (_categoryId == categoryId) {
      return;
    }
    setState(() => _categoryId = categoryId);
    _loadMaterials();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskEditorPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t(context, '学习素材', 'Learning material'),
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _MaterialSearchField(
                controller: _keywordController,
                onSubmitted: (_) => _loadMaterials(),
                onSearch: () => _loadMaterials(),
              ),
              const SizedBox(height: 12),
              _MaterialCategoryChips(
                categories: _categories,
                selectedCategoryId: _categoryId,
                onSelected: _selectCategory,
              ),
              const SizedBox(height: 12),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 54),
                  child: const CircularProgressIndicator(
                    color: Color(0xFFFF9585),
                  ),
                )
              else if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _loadMaterials(
                          includeCategories: _categories.isEmpty,
                        ),
                        child: Text(_t(context, '重试', 'Retry')),
                      ),
                    ],
                  ),
                )
              else if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 42),
                  child: Text(
                    _t(context, '没有匹配的教育素材', 'No matching learning materials'),
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 15,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.42,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final selected = _selectedIds.contains(item.id);
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _toggleMaterial(item),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          decoration: BoxDecoration(
                            color: selected
                                ? palette.selectedChipBackground
                                : palette.softBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFFFE8E3)
                                      : const Color(0xFFEAF1FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _materialIcon(item.mediaType),
                                  color: selected
                                      ? const Color(0xFFFF9585)
                                      : const Color(0xFF5A81DA),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.primaryText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: selected
                                    ? const Color(0xFFFF9585)
                                    : palette.outline,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  _selectedIds
                      .map((id) => _selectedItemsById[id])
                      .whereType<MaterialItem>()
                      .toList(growable: false),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF5A81DA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
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
}

class _MaterialSearchField extends StatelessWidget {
  const _MaterialSearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onSearch,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskEditorPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              isDense: true,
              hintText: _t(context, '输入关键词', 'Search materials'),
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: palette.softBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              hintStyle: TextStyle(color: palette.mutedText),
            ),
            style: TextStyle(color: palette.primaryText, fontSize: 15),
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: onSearch,
          child: Text(_t(context, '搜索', 'Search')),
        ),
      ],
    );
  }
}

class _MaterialCategoryChips extends StatelessWidget {
  const _MaterialCategoryChips({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<MaterialCategory> categories;
  final int selectedCategoryId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskEditorPalette.of(context);
    final items = [
      MaterialCategory(
        id: 0,
        parentId: 0,
        name: _t(context, '全部', 'All'),
        type: 'education',
        icon: '',
        sort: 0,
      ),
      ...categories,
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = item.id == selectedCategoryId;
          return ChoiceChip(
            label: Text(item.name),
            selected: selected,
            onSelected: (_) => onSelected(item.id),
            labelStyle: TextStyle(
              color: selected ? Colors.white : palette.primaryText,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: const Color(0xFFFF9585),
            backgroundColor: palette.softBackground,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskEditorPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

class _EditorTextRow extends StatelessWidget {
  const _EditorTextRow({
    required this.label,
    required this.controller,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskEditorPalette.of(context);
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
              keyboardType: keyboardType,
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

class _EditorActionRow extends StatelessWidget {
  const _EditorActionRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskEditorPalette.of(context);
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
                value,
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

class _EditorSwitchRow extends StatelessWidget {
  const _EditorSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorTaskEditorPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: palette.secondaryText, fontSize: 16),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFFFF9585),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

String _taskTypeLabel(BuildContext context, String value) {
  return switch (value) {
    'assessment' => _t(context, '评估量表', 'Assessment'),
    'material' => _t(context, '素材学习', 'Learning material'),
    'checkin' => _t(context, '打卡签到', 'Check-in'),
    _ => _t(context, '日常任务', 'Daily task'),
  };
}

String _formatTime(TimeOfDay? value) {
  if (value == null) {
    return '--:--';
  }
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _timeValue(TimeOfDay? value) {
  if (value == null) {
    return '';
  }
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute:00';
}

DateTime? _parseDate(String value) {
  final parsed = DateTime.tryParse(value.trim());
  return parsed;
}

TimeOfDay? _parseClockTime(String value) {
  final parts = value.trim().split(':');
  if (parts.length < 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }
  return TimeOfDay(hour: hour, minute: minute);
}

Map<String, dynamic> _learningMaterialPayload(MaterialItem item) {
  return {
    'material_id': item.id,
    'title': item.title,
    'media_type': item.mediaType,
  };
}

Map<String, dynamic> _templateLearningMaterialPayload(
  DailyTaskAttachment item,
) {
  return {
    'material_id': item.materialId,
    'title': item.displayTitle,
    'media_type': item.mediaType,
  };
}

List<Map<String, dynamic>> _learningMaterialPayloads(
  List<MaterialItem> selectedMaterials,
  List<DailyTaskAttachment> templateMaterials,
) {
  if (selectedMaterials.isNotEmpty) {
    return selectedMaterials
        .map(_learningMaterialPayload)
        .toList(growable: false);
  }
  return templateMaterials
      .where((item) => item.materialId > 0 || item.displayTitle.isNotEmpty)
      .map(_templateLearningMaterialPayload)
      .toList(growable: false);
}

String _learningMaterialSummary(
  BuildContext context,
  List<MaterialItem> materials,
  List<DailyTaskAttachment> templateMaterials,
) {
  if (materials.isEmpty) {
    if (templateMaterials.isEmpty) {
      return _t(context, '无', 'None');
    }
    if (templateMaterials.length == 1) {
      return templateMaterials.first.displayTitle;
    }
    return _t(
      context,
      '${templateMaterials.first.displayTitle} 等${templateMaterials.length}项',
      '${templateMaterials.length} selected',
    );
  }
  if (materials.length == 1) {
    return materials.first.title;
  }
  return _t(
    context,
    '${materials.first.title} 等${materials.length}项',
    '${materials.length} selected',
  );
}

IconData _materialIcon(String mediaType) {
  switch (mediaType) {
    case 'video':
      return Icons.play_circle_fill_rounded;
    case 'audio':
      return Icons.headphones_rounded;
    case 'pdf':
    case 'document':
      return Icons.description_rounded;
    default:
      return Icons.menu_book_rounded;
  }
}

Widget _editorDivider(BuildContext context) {
  return Divider(
    height: 1,
    color: _DoctorTaskEditorPalette.of(context).outline,
  );
}

class _DoctorTaskEditorPalette {
  const _DoctorTaskEditorPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.sheetBackground,
    required this.softBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.outline,
    required this.selectedChipBackground,
  });

  factory _DoctorTaskEditorPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _DoctorTaskEditorPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      sheetBackground: scheme.surfaceContainerLowest,
      softBackground: scheme.surfaceContainerLow,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
          : const Color(0xFF7D828A),
      outline: scheme.outlineVariant,
      selectedChipBackground: isDark
          ? scheme.primaryContainer
          : const Color(0xFFEAF0FF),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color sheetBackground;
  final Color softBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color outline;
  final Color selectedChipBackground;
}
