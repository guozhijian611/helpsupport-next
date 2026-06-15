import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/centered_notice.dart';
import '../application/doctor_controller.dart';
import '../data/doctor_models.dart';

class DoctorAssessmentScalesScreen extends ConsumerStatefulWidget {
  const DoctorAssessmentScalesScreen({super.key});

  @override
  ConsumerState<DoctorAssessmentScalesScreen> createState() =>
      _DoctorAssessmentScalesScreenState();
}

class _DoctorAssessmentScalesScreenState
    extends ConsumerState<DoctorAssessmentScalesScreen> {
  String _status = 'published';

  @override
  Widget build(BuildContext context) {
    final query = DoctorAssessmentScalesQuery(status: _status);
    final scales = ref.watch(doctorAssessmentScalesProvider(query));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: Text(_t(context, '评估量表', 'Assessment scales')),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openCreateScaleSheet,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Row(
              children: [
                _TabItem(
                  label: _t(context, '已完成', 'Published'),
                  active: _status == 'published',
                  onTap: () => setState(() => _status = 'published'),
                ),
                const SizedBox(width: 28),
                _TabItem(
                  label: _t(context, '草稿箱', 'Drafts'),
                  active: _status == 'draft',
                  onTap: () => setState(() => _status = 'draft'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(doctorAssessmentScalesProvider(query));
            await ref.read(doctorAssessmentScalesProvider(query).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              scales.when(
                data: (items) {
                  if (items.isEmpty) {
                    return _EmptyScaleBlock(
                      title: _t(context, '还没有量表', 'No scales yet'),
                      subtitle: _t(
                        context,
                        '可以通过右上角创建新的量表草稿。',
                        'Create a new draft scale from the top-right action.',
                      ),
                      onCreate: _openCreateScaleSheet,
                    );
                  }
                  return Column(
                    children: [
                      for (final scale in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ScaleCard(
                            scale: scale,
                            showPublishButton:
                                _status == 'draft' && scale.doctorId > 0,
                            onPublish: () => _publishScale(scale),
                          ),
                        ),
                    ],
                  );
                },
                error: (error, _) => _EmptyScaleBlock(
                  title: _t(context, '加载失败', 'Load failed'),
                  subtitle: error.toString(),
                  onCreate: () =>
                      ref.invalidate(doctorAssessmentScalesProvider(query)),
                ),
                loading: () => const _ScaleListSkeleton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publishScale(DoctorAssessmentScale scale) async {
    try {
      await ref.read(doctorRepositoryProvider).publishAssessmentScale(scale.id);
      ref.invalidate(doctorAssessmentScalesProvider);
      if (mounted) {
        context.showCenteredNotice(_t(context, '量表已发布', 'Scale published'));
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    }
  }

  Future<void> _openCreateScaleSheet() async {
    final titleController = TextEditingController();
    final stageController = TextEditingController();
    final descriptionController = TextEditingController();
    final scoreController = TextEditingController(text: '0');
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(context, '新建量表', 'New scale'),
                style: const TextStyle(
                  color: Color(0xFF303236),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _SheetField(
                controller: titleController,
                hintText: _t(context, '量表名称', 'Scale title'),
              ),
              const SizedBox(height: 12),
              _SheetField(
                controller: stageController,
                hintText: _t(context, '所属阶段（可选）', 'Stage (optional)'),
              ),
              const SizedBox(height: 12),
              _SheetField(
                controller: scoreController,
                hintText: _t(context, '总分', 'Total score'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _SheetField(
                controller: descriptionController,
                hintText: _t(context, '量表简介', 'Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(_t(context, '取消', 'Cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9585),
                      ),
                      child: Text(_t(context, '保存', 'Save')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (created != true) {
      titleController.dispose();
      stageController.dispose();
      descriptionController.dispose();
      scoreController.dispose();
      return;
    }

    final title = titleController.text.trim();
    final stage = stageController.text.trim();
    final description = descriptionController.text.trim();
    final score = int.tryParse(scoreController.text.trim()) ?? 0;
    titleController.dispose();
    stageController.dispose();
    descriptionController.dispose();
    scoreController.dispose();
    if (title.isEmpty) {
      if (mounted) {
        context.showCenteredNotice(
          _t(context, '请先填写量表名称', 'Please enter a scale title'),
        );
      }
      return;
    }
    try {
      await ref
          .read(doctorRepositoryProvider)
          .saveAssessmentScale(
            title: title,
            stage: stage,
            description: description,
            totalScore: score,
          );
      ref.invalidate(doctorAssessmentScalesProvider);
      if (mounted) {
        context.showCenteredNotice(_t(context, '量表草稿已保存', 'Draft scale saved'));
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    }
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF5A81DA) : const Color(0xFF303236),
              fontSize: 18,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 44,
            height: 3,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF5A81DA) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleCard extends StatelessWidget {
  const _ScaleCard({
    required this.scale,
    required this.showPublishButton,
    required this.onPublish,
  });

  final DoctorAssessmentScale scale;
  final bool showPublishButton;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF7E7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: Color(0xFF69CB69),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scale.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF303236),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (scale.stage.isNotEmpty) scale.stage,
                    _t(
                      context,
                      '总分 ${scale.totalScore}',
                      'Score ${scale.totalScore}',
                    ),
                    scale.isPublished
                        ? _t(context, '已发布', 'Published')
                        : _t(context, '草稿', 'Draft'),
                  ].join(' · '),
                  style: const TextStyle(
                    color: Color(0xFF7D828A),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (showPublishButton)
            TextButton(
              onPressed: onPublish,
              child: Text(_t(context, '发布', 'Publish')),
            ),
        ],
      ),
    );
  }
}

class _EmptyScaleBlock extends StatelessWidget {
  const _EmptyScaleBlock({
    required this.title,
    required this.subtitle,
    required this.onCreate,
  });

  final String title;
  final String subtitle;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8C919A),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9585),
            ),
            child: Text(_t(context, '新建量表', 'Create scale')),
          ),
        ],
      ),
    );
  }
}

class _ScaleListSkeleton extends StatelessWidget {
  const _ScaleListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(
        6,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF7F8FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
