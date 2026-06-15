import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/centered_notice.dart';
import '../application/doctor_controller.dart';
import '../data/doctor_models.dart';

class DoctorAssessmentScaleEditorScreen extends ConsumerStatefulWidget {
  const DoctorAssessmentScaleEditorScreen({super.key, this.initialScale});

  final DoctorAssessmentScale? initialScale;

  @override
  ConsumerState<DoctorAssessmentScaleEditorScreen> createState() =>
      _DoctorAssessmentScaleEditorScreenState();
}

class _DoctorAssessmentScaleEditorScreenState
    extends ConsumerState<DoctorAssessmentScaleEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _scoreController;
  late List<_EditableAssessmentQuestion> _questions;
  bool _saving = false;

  bool get _editing => widget.initialScale != null;

  @override
  void initState() {
    super.initState();
    final scale = widget.initialScale;
    _titleController = TextEditingController(text: scale?.title ?? '');
    _descriptionController = TextEditingController(
      text: scale?.description ?? '',
    );
    _scoreController = TextEditingController(
      text: '${scale?.totalScore ?? 100}',
    );
    _questions = (scale?.questions ?? const <DoctorAssessmentQuestion>[])
        .map(_EditableAssessmentQuestion.fromQuestion)
        .toList(growable: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: Text(
          _editing
              ? _t(context, '编辑评估量表', 'Edit assessment scale')
              : _t(context, '新建评估量表', 'New assessment scale'),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_t(context, '保存', 'Save')),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            _EditorCard(
              child: Column(
                children: [
                  _EditorField(
                    label: _t(context, '量表名称', 'Scale title'),
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: _t(
                          context,
                          '例如：抑郁自评量表PHQ-9',
                          'Example: Depression self-rating PHQ-9',
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF303236),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _EditorField(
                    label: _t(context, '简介', 'Description'),
                    child: TextField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: _t(
                          context,
                          '填写量表说明或指导语',
                          'Add a short introduction or guidance',
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF303236),
                        fontSize: 17,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _EditorField(
                    label: _t(context, '分值', 'Total score'),
                    child: TextField(
                      controller: _scoreController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF303236),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _EditorCard(
              child: Column(
                children: [
                  for (var index = 0; index < _questions.length; index++) ...[
                    if (index > 0)
                      const Divider(height: 1, color: Color(0xFFE8EBF1)),
                    _QuestionTile(
                      index: index,
                      question: _questions[index],
                      onTap: () => _editQuestion(index),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: OutlinedButton(
                      onPressed: () => _editQuestion(null),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        side: const BorderSide(color: Color(0xFF5A81DA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _t(context, '+ 添加题目', '+ Add question'),
                        style: const TextStyle(
                          color: Color(0xFF5A81DA),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 18),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editQuestion(int? index) async {
    final initial = index == null ? null : _questions[index];
    final result = await showModalBottomSheet<_EditableAssessmentQuestion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuestionEditorSheet(initial: initial),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      if (index == null) {
        _questions.add(result);
      } else {
        _questions[index] = result;
      }
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      context.showCenteredNotice(
        _t(context, '请先填写量表名称', 'Please enter a scale title'),
      );
      return;
    }
    if (_questions.isEmpty) {
      context.showCenteredNotice(
        _t(context, '请至少添加一个题目', 'Please add at least one question'),
      );
      return;
    }
    final totalScore = int.tryParse(_scoreController.text.trim()) ?? 100;
    if (totalScore <= 0) {
      context.showCenteredNotice(
        _t(context, '请填写正确的分值', 'Please enter a valid score'),
      );
      return;
    }
    final questions = _questions
        .map((item) => item.toQuestion().toJson())
        .toList(growable: false);
    final confirmed = await _confirmDraftSave();
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(doctorRepositoryProvider)
          .saveAssessmentScale(
            id: widget.initialScale?.id ?? '',
            title: title,
            description: _descriptionController.text.trim(),
            totalScore: totalScore,
            questions: questions,
            scoringRule: _buildScoringRules(totalScore),
          );
      ref.invalidate(doctorAssessmentScalesProvider);
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        _editing
            ? _t(context, '量表草稿已更新', 'Draft scale updated')
            : _t(context, '量表草稿已保存', 'Draft scale saved'),
      );
      Navigator.of(context).pop(true);
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

  List<Map<String, dynamic>> _buildScoringRules(int totalScore) {
    final mediumMin = (totalScore * 0.4).ceil();
    final highMin = (totalScore * 0.7).ceil();
    final mediumMax = highMin > 0 ? highMin - 1 : 0;
    final lightMax = mediumMin > 0 ? mediumMin - 1 : 0;
    final rules = <DoctorAssessmentScoreRule>[];

    void addRule(DoctorAssessmentScoreRule rule) {
      if (rule.minScore <= rule.maxScore) {
        rules.add(rule);
      }
    }

    addRule(
      DoctorAssessmentScoreRule(
        label: _t(context, '轻度波动', 'Mild'),
        minScore: 0,
        maxScore: lightMax.clamp(0, totalScore),
        suggestion: _t(
          context,
          '当前状态相对稳定，继续保持现有治疗节奏即可。',
          'Your current state looks stable. Keep following the current plan.',
        ),
      ),
    );
    addRule(
      DoctorAssessmentScoreRule(
        label: _t(context, '中度波动', 'Moderate'),
        minScore: mediumMin.clamp(0, totalScore),
        maxScore: mediumMax.clamp(0, totalScore),
        suggestion: _t(
          context,
          '建议保持规律记录和复测，观察近期情绪与睡眠波动。',
          'Keep a regular record and monitor recent mood and sleep changes.',
        ),
      ),
    );
    addRule(
      DoctorAssessmentScoreRule(
        label: _t(context, '高风险', 'High risk'),
        minScore: highMin.clamp(0, totalScore),
        maxScore: totalScore,
        suggestion: _t(
          context,
          '建议尽快和医生或治疗师复盘当前状态，并及时调整治疗计划。',
          'Review your current condition with your doctor or therapist as soon as possible.',
        ),
      ),
    );

    return rules.map((item) => item.toJson()).toList(growable: false);
  }

  Future<bool?> _confirmDraftSave() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t(context, '保存', 'Save')),
        content: Text(_t(context, '保存到草稿箱？', 'Save to drafts?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t(context, '取消', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_t(context, '确认', 'Confirm')),
          ),
        ],
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.child});

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

class _EditorField extends StatelessWidget {
  const _EditorField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.index,
    required this.question,
    required this.onTap,
  });

  final int index;
  final _EditableAssessmentQuestion question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t(context, '题目${index + 1}', 'Question ${index + 1}'),
              style: const TextStyle(
                color: Color(0xFF303236),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF303236),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFC6CAD2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionEditorSheet extends StatefulWidget {
  const _QuestionEditorSheet({this.initial});

  final _EditableAssessmentQuestion? initial;

  @override
  State<_QuestionEditorSheet> createState() => _QuestionEditorSheetState();
}

class _QuestionEditorSheetState extends State<_QuestionEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _countController;
  late List<_OptionDraft> _options;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _options = (initial?.options ?? _defaultOptions())
        .map((item) => _OptionDraft.fromOption(item))
        .toList(growable: true);
    _countController = TextEditingController(text: '${_options.length}');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _countController.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    Text(
                      _t(context, '添加题目', 'Add question'),
                      style: const TextStyle(
                        color: Color(0xFF303236),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _EditorField(
                  label: _t(context, '题目名称', 'Question title'),
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: _t(
                        context,
                        '例如：我感到焦虑或紧张',
                        'Example: I feel anxious or tense',
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF303236),
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _EditorField(
                  label: _t(context, '选项数量', 'Option count'),
                  child: TextField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    onChanged: _applyOptionCount,
                    decoration: const InputDecoration(border: InputBorder.none),
                    style: const TextStyle(
                      color: Color(0xFF303236),
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < _options.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 74,
                          child: Text(
                            _t(
                              context,
                              '选项${index + 1}',
                              'Option ${index + 1}',
                            ),
                            style: const TextStyle(
                              color: Color(0xFFB0B3BA),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _options[index].labelController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                color: Color(0xFF303236),
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _t(context, '分值', 'Score'),
                          style: const TextStyle(
                            color: Color(0xFFB0B3BA),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 64,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _options[index].scoreController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                color: Color(0xFF303236),
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: const Color(0xFF5A81DA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    _t(context, '确定', 'Confirm'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyOptionCount(String value) {
    final count = int.tryParse(value.trim()) ?? _options.length;
    final nextCount = count.clamp(2, 8);
    if (nextCount == _options.length) {
      return;
    }
    setState(() {
      if (nextCount > _options.length) {
        while (_options.length < nextCount) {
          final index = _options.length;
          _options.add(
            _OptionDraft(
              labelController: TextEditingController(
                text: _defaultOptionLabel(context, index),
              ),
              scoreController: TextEditingController(
                text: '${(nextCount - index).clamp(0, 999)}',
              ),
            ),
          );
        }
      } else {
        while (_options.length > nextCount) {
          _options.removeLast().dispose();
        }
      }
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }
    final options = <DoctorAssessmentOption>[];
    for (var index = 0; index < _options.length; index++) {
      final label = _options[index].labelController.text.trim();
      if (label.isEmpty) {
        return;
      }
      final initialOptions = widget.initial?.options ?? const [];
      final existingOption = index < initialOptions.length
          ? initialOptions[index]
          : null;
      options.add(
        DoctorAssessmentOption(
          id:
              existingOption?.id ??
              'opt-${DateTime.now().microsecondsSinceEpoch}-$index',
          label: label,
          score: int.tryParse(_options[index].scoreController.text.trim()) ?? 0,
        ),
      );
    }

    Navigator.of(context).pop(
      _EditableAssessmentQuestion(
        id:
            widget.initial?.id ??
            'q-${DateTime.now().microsecondsSinceEpoch}-${options.length}',
        title: title,
        options: options,
      ),
    );
  }

  List<DoctorAssessmentOption> _defaultOptions() {
    return List<DoctorAssessmentOption>.generate(
      5,
      (index) => DoctorAssessmentOption(
        id: 'opt-${DateTime.now().microsecondsSinceEpoch}-$index',
        label: index == 0
            ? '没有'
            : index == 1
            ? '偶尔'
            : index == 2
            ? '一般'
            : index == 3
            ? '有时'
            : '经常',
        score: 5 - index,
      ),
      growable: false,
    );
  }

  String _defaultOptionLabel(BuildContext context, int index) {
    const labelsZh = ['没有', '偶尔', '一般', '有时', '经常', '频繁', '总是', '非常严重'];
    const labelsEn = [
      'Never',
      'Occasionally',
      'Sometimes',
      'Often',
      'Usually',
      'Frequently',
      'Always',
      'Severe',
    ];
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final source = zh ? labelsZh : labelsEn;
    return index < source.length
        ? source[index]
        : '${zh ? '选项' : 'Option'} ${index + 1}';
  }
}

class _EditableAssessmentQuestion {
  const _EditableAssessmentQuestion({
    required this.id,
    required this.title,
    required this.options,
  });

  final String id;
  final String title;
  final List<DoctorAssessmentOption> options;

  factory _EditableAssessmentQuestion.fromQuestion(
    DoctorAssessmentQuestion value,
  ) {
    return _EditableAssessmentQuestion(
      id: value.id,
      title: value.title,
      options: value.options,
    );
  }

  DoctorAssessmentQuestion toQuestion() {
    return DoctorAssessmentQuestion(id: id, title: title, options: options);
  }
}

class _OptionDraft {
  _OptionDraft({required this.labelController, required this.scoreController});

  final TextEditingController labelController;
  final TextEditingController scoreController;

  factory _OptionDraft.fromOption(DoctorAssessmentOption option) {
    return _OptionDraft(
      labelController: TextEditingController(text: option.label),
      scoreController: TextEditingController(text: '${option.score}'),
    );
  }

  void dispose() {
    labelController.dispose();
    scoreController.dispose();
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
