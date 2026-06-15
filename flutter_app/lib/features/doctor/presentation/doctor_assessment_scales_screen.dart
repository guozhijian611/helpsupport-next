import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            onPressed: _openEditor,
            icon: const Icon(Icons.add_circle, color: Color(0xFF5A81DA)),
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
                        '先创建量表草稿，再补充题目并发布给患者使用。',
                        'Create a draft scale, add questions, then publish it for patients.',
                      ),
                      onCreate: _openEditor,
                    );
                  }
                  return Column(
                    children: [
                      for (final scale in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ScaleCard(
                            scale: scale,
                            draftMode: _status == 'draft',
                            onTap: _status == 'draft' && scale.doctorId > 0
                                ? () => _openEditor(scale)
                                : null,
                            onPublish: _status == 'draft' && scale.doctorId > 0
                                ? () => _publishScale(scale)
                                : null,
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

  Future<void> _openEditor([DoctorAssessmentScale? scale]) async {
    final changed = await context.push<bool>(
      '/doctor/assessment-scales/editor',
      extra: scale,
    );
    if (changed == true) {
      ref.invalidate(doctorAssessmentScalesProvider);
    }
  }

  Future<void> _publishScale(DoctorAssessmentScale scale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t(context, '保存', 'Save')),
        content: Text(_t(context, '保存到已完成？', 'Move to published?')),
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
    if (confirmed != true) {
      return;
    }

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
    required this.draftMode,
    this.onTap,
    this.onPublish,
  });

  final DoctorAssessmentScale scale;
  final bool draftMode;
  final VoidCallback? onTap;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
                        _t(
                          context,
                          '${scale.questions.length} 题',
                          '${scale.questions.length} questions',
                        ),
                        _t(
                          context,
                          '总分 ${scale.totalScore}',
                          'Score ${scale.totalScore}',
                        ),
                      ].join(' · '),
                      style: const TextStyle(
                        color: Color(0xFF7D828A),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (draftMode && onPublish != null)
                IconButton(
                  onPressed: onPublish,
                  icon: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF68C140),
                    size: 32,
                  ),
                )
              else if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFC6CAD2),
                ),
            ],
          ),
        ),
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
              backgroundColor: const Color(0xFF5A81DA),
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

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
