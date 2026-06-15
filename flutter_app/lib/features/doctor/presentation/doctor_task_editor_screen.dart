import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/centered_notice.dart';
import '../application/doctor_controller.dart';

class DoctorTaskEditorScreen extends ConsumerStatefulWidget {
  const DoctorTaskEditorScreen({
    super.key,
    required this.memberId,
    required this.planId,
    required this.stageId,
    this.initialDate = '',
  });

  final int memberId;
  final int planId;
  final int stageId;
  final String initialDate;

  @override
  ConsumerState<DoctorTaskEditorScreen> createState() =>
      _DoctorTaskEditorScreenState();
}

class _DoctorTaskEditorScreenState
    extends ConsumerState<DoctorTaskEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _rewardController;
  late DateTime _taskDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _taskType = 'daily';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _rewardController = TextEditingController(text: '20');
    _taskDate = _parseDate(widget.initialDate) ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
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
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
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
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _EditorActionRow(
                    label: _t(context, '任务类型', 'Task type'),
                    value: _taskTypeLabel(context, _taskType),
                    onTap: _pickTaskType,
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _EditorActionRow(
                    label: _t(context, '日期选择', 'Task date'),
                    value: DateFormat('yyyy-MM-dd').format(_taskDate),
                    onTap: _pickDate,
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _EditorActionRow(
                    label: _t(context, '开始时间', 'Start time'),
                    value: _formatTime(_startTime),
                    onTap: () => _pickTime(isStart: true),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _EditorActionRow(
                    label: _t(context, '结束时间', 'End time'),
                    value: _formatTime(_endTime),
                    onTap: () => _pickTime(isStart: false),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _EditorTextRow(
                    label: _t(context, '奖励分数', 'Reward score'),
                    controller: _rewardController,
                    hintText: '20',
                    keyboardType: TextInputType.number,
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _EditorStaticRow(
                    label: _t(context, '附件选择', 'Attachments'),
                    value: _t(context, '无', 'None'),
                  ),
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

  Future<void> _pickTaskType() async {
    final value = await showModalBottomSheet<String>(
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
                _t(context, '任务类型', 'Task type'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF303236),
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
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  tileColor: item == _taskType
                      ? const Color(0xFFEAF0FF)
                      : const Color(0xFFF7F8FB),
                  title: Text(_taskTypeLabel(context, item)),
                  onTap: () => Navigator.of(context).pop(item),
                ),
            ],
          ),
        ),
      ),
    );
    if (value != null && mounted) {
      setState(() => _taskType = value);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      context.showCenteredNotice(
        _t(context, '请先填写任务名称', 'Please enter a task name'),
      );
      return;
    }

    setState(() => _saving = true);
    try {
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
            pointsReward: int.tryParse(_rewardController.text.trim()) ?? 20,
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

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
              keyboardType: keyboardType,
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
                value,
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

class _EditorStaticRow extends StatelessWidget {
  const _EditorStaticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Text(
            value,
            style: const TextStyle(color: Color(0xFF9AA0A8), fontSize: 16),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFC8CDD6)),
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
