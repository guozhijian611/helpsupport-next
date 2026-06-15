import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/centered_notice.dart';
import '../../plan/data/plan_models.dart';
import '../application/doctor_controller.dart';

class DoctorTreatmentStageScreen extends ConsumerStatefulWidget {
  const DoctorTreatmentStageScreen({
    super.key,
    required this.memberId,
    required this.planId,
    this.stage,
  });

  final int memberId;
  final int planId;
  final TreatmentStage? stage;

  @override
  ConsumerState<DoctorTreatmentStageScreen> createState() =>
      _DoctorTreatmentStageScreenState();
}

class _DoctorTreatmentStageScreenState
    extends ConsumerState<DoctorTreatmentStageScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _sortController;
  late DateTime _startDate;
  late DateTime _endDate;
  late int _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final stage = widget.stage;
    _nameController = TextEditingController(text: stage?.stageName ?? '');
    _targetController = TextEditingController(text: stage?.description ?? '');
    _sortController = TextEditingController(
      text: stage != null ? '${stage.sort}' : '',
    );
    _startDate = _parseDate(stage?.startDate, fallback: now);
    _endDate = _parseDate(stage?.endDate, fallback: _startDate);
    _status = stage?.status ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: Text(
          widget.stage == null
              ? _t(context, '添加阶段', 'Add stage')
              : _t(context, '编辑阶段', 'Edit stage'),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            _FieldCard(
              child: Column(
                children: [
                  _TextFieldRow(
                    label: _t(context, '阶段名称', 'Stage name'),
                    controller: _nameController,
                    hintText: _t(
                      context,
                      '例如：适应期 / 巩固期',
                      'Example: Adaptation / Consolidation',
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _ActionRow(
                    label: _t(context, '开始日期', 'Start date'),
                    value: _formatDate(_startDate),
                    onTap: () => _pickDate(isStart: true),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _ActionRow(
                    label: _t(context, '结束日期', 'End date'),
                    value: _formatDate(_endDate),
                    onTap: () => _pickDate(isStart: false),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _TextFieldRow(
                    label: _t(context, '阶段目标', 'Stage goal'),
                    controller: _targetController,
                    hintText: _t(
                      context,
                      '描述本阶段重点目标',
                      'Describe the focus of this stage',
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _ActionRow(
                    label: _t(context, '阶段状态', 'Stage status'),
                    value: _stageStatusLabel(context, _status),
                    onTap: _pickStatus,
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBF1)),
                  _TextFieldRow(
                    label: _t(context, '排序', 'Sort'),
                    controller: _sortController,
                    hintText: _t(context, '留空自动排序', 'Auto sort if empty'),
                    keyboardType: TextInputType.number,
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

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
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
                _t(context, '阶段状态', 'Stage status'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF303236),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              for (final item in const [0, 1, 2])
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  tileColor: item == _status
                      ? const Color(0xFFEAF0FF)
                      : const Color(0xFFF7F8FB),
                  title: Text(_stageStatusLabel(context, item)),
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

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      context.showCenteredNotice(
        _t(context, '请先填写阶段名称', 'Please enter a stage name'),
      );
      return;
    }
    if (_endDate.isBefore(_startDate)) {
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
      await ref
          .read(doctorRepositoryProvider)
          .saveTreatmentStage(
            memberId: widget.memberId,
            planId: widget.planId,
            id: widget.stage?.id ?? 0,
            stageName: _nameController.text,
            startDate: _formatDate(_startDate),
            endDate: _formatDate(_endDate),
            stageTarget: _targetController.text,
            sort: int.tryParse(_sortController.text.trim()) ?? 0,
            status: _status,
          );
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(_t(context, '阶段已保存', 'Stage saved'));
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

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.child});

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

class _TextFieldRow extends StatelessWidget {
  const _TextFieldRow({
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
              keyboardType: keyboardType,
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
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

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

String _stageStatusLabel(BuildContext context, int value) {
  return switch (value) {
    1 => _t(context, '进行中', 'In progress'),
    2 => _t(context, '已完成', 'Completed'),
    _ => _t(context, '待开始', 'Pending'),
  };
}

String _formatDate(DateTime value) {
  return DateFormat('yyyy-MM-dd').format(value);
}

DateTime _parseDate(String? value, {required DateTime fallback}) {
  final parsed = DateTime.tryParse((value ?? '').trim());
  return parsed ?? fallback;
}
