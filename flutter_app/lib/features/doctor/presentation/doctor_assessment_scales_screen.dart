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
  _ScaleSourceFilter _sourceFilter = _ScaleSourceFilter.all;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorAssessmentScalesPalette.of(context);
    final query = DoctorAssessmentScalesQuery(status: _status);
    final scales = ref.watch(doctorAssessmentScalesProvider(query));

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
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
              _ScaleSourceFilterBar(
                value: _sourceFilter,
                onChanged: (value) => setState(() => _sourceFilter = value),
              ),
              const SizedBox(height: 14),
              scales.when(
                data: (items) {
                  final visibleItems = items
                      .where((item) => _matchesSource(item.doctorId))
                      .toList(growable: false);
                  if (visibleItems.isEmpty) {
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
                      for (final scale in visibleItems) ...[
                        Builder(
                          builder: (context) {
                            final canEdit =
                                _status == 'draft' && scale.doctorId > 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ScaleCard(
                                scale: scale,
                                draftMode: _status == 'draft',
                                onTap: canEdit
                                    ? () => _openEditor(scale)
                                    : () => _openScaleDetail(scale),
                                onPublish: canEdit
                                    ? () => _publishScale(scale)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ],
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

  bool _matchesSource(int doctorId) {
    return switch (_sourceFilter) {
      _ScaleSourceFilter.all => true,
      _ScaleSourceFilter.system => doctorId == 0,
      _ScaleSourceFilter.mine => doctorId > 0,
    };
  }

  Future<void> _openEditor([DoctorAssessmentScale? scale]) async {
    final changed = await context.push<bool>(
      '/doctor/assessment-scales/editor',
      extra: scale,
    );
    if (!mounted) {
      return;
    }
    if (changed == true) {
      ref.invalidate(doctorAssessmentScalesProvider);
    }
  }

  Future<void> _openScaleDetail(DoctorAssessmentScale scale) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ScaleDetailSheet(scale: scale),
    );
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
    if (confirmed != true || !mounted) {
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
    final palette = _DoctorAssessmentScalesPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF5A81DA) : palette.primaryText,
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

enum _ScaleSourceFilter { all, system, mine }

class _ScaleSourceFilterBar extends StatelessWidget {
  const _ScaleSourceFilterBar({required this.value, required this.onChanged});

  final _ScaleSourceFilter value;
  final ValueChanged<_ScaleSourceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorAssessmentScalesPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _ScaleSourceFilterButton(
            label: _t(context, '全部', 'All'),
            selected: value == _ScaleSourceFilter.all,
            onTap: () => onChanged(_ScaleSourceFilter.all),
          ),
          _ScaleSourceFilterButton(
            label: _t(context, '系统预设', 'System'),
            selected: value == _ScaleSourceFilter.system,
            onTap: () => onChanged(_ScaleSourceFilter.system),
          ),
          _ScaleSourceFilterButton(
            label: _t(context, '我的创建', 'Mine'),
            selected: value == _ScaleSourceFilter.mine,
            onTap: () => onChanged(_ScaleSourceFilter.mine),
          ),
        ],
      ),
    );
  }
}

class _ScaleSourceFilterButton extends StatelessWidget {
  const _ScaleSourceFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorAssessmentScalesPalette.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF1FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? const Color(0xFF5A81DA) : palette.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
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
    final palette = _DoctorAssessmentScalesPalette.of(context);
    return Material(
      color: palette.cardBackground,
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
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    _ScaleSourceBadge(isSystem: scale.doctorId == 0),
                    const SizedBox(height: 9),
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
                      style: TextStyle(color: palette.mutedText, fontSize: 14),
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
                Icon(Icons.chevron_right_rounded, color: palette.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScaleDetailSheet extends StatelessWidget {
  const _ScaleDetailSheet({required this.scale});

  final DoctorAssessmentScale scale;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorAssessmentScalesPalette.of(context);
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.pageBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: palette.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scale.title,
                              style: TextStyle(
                                color: palette.primaryText,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _ScaleSourceBadge(isSystem: scale.doctorId == 0),
                            const SizedBox(height: 10),
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
                                scale.stage,
                              ].where((item) => item.isNotEmpty).join(' · '),
                              style: TextStyle(
                                color: palette.mutedText,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  if (scale.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      scale.description,
                      style: TextStyle(
                        color: palette.mutedText,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _DetailSectionTitle(
                    title: _t(context, '题目', 'Questions'),
                    count: scale.questions.length,
                  ),
                  const SizedBox(height: 10),
                  if (scale.questions.isEmpty)
                    _DetailEmptyText(
                      text: _t(context, '暂无题目配置', 'No questions configured'),
                    )
                  else
                    for (var index = 0; index < scale.questions.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QuestionDetailCard(
                          index: index,
                          question: scale.questions[index],
                        ),
                      ),
                  const SizedBox(height: 8),
                  _DetailSectionTitle(
                    title: _t(context, '评分规则', 'Scoring rules'),
                    count: scale.scoringRule.length,
                  ),
                  const SizedBox(height: 10),
                  if (scale.scoringRule.isEmpty)
                    _DetailEmptyText(
                      text: _t(context, '暂无评分规则', 'No scoring rules'),
                    )
                  else
                    for (final rule in scale.scoringRule)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ScoreRuleCard(rule: rule),
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

class _ScaleSourceBadge extends StatelessWidget {
  const _ScaleSourceBadge({required this.isSystem});

  final bool isSystem;

  @override
  Widget build(BuildContext context) {
    final label = isSystem
        ? _t(context, '系统预设', 'System')
        : _t(context, '我的创建', 'Mine');
    final color = isSystem ? const Color(0xFF5A81DA) : const Color(0xFFFF9585);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorAssessmentScalesPalette.of(context);
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: palette.primaryText,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: TextStyle(
            color: palette.mutedText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _QuestionDetailCard extends StatelessWidget {
  const _QuestionDetailCard({required this.index, required this.question});

  final int index;
  final DoctorAssessmentQuestion question;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorAssessmentScalesPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${question.title}',
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in question.options)
                _OptionScoreChip(option: option),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionScoreChip extends StatelessWidget {
  const _OptionScoreChip({required this.option});

  final DoctorAssessmentOption option;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorAssessmentScalesPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.cardBackground == Colors.white
            ? const Color(0xFFF4F5F9)
            : palette.outline.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${option.label} · ${option.score}',
        style: const TextStyle(
          color: Color(0xFF5A81DA),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ScoreRuleCard extends StatelessWidget {
  const _ScoreRuleCard({required this.rule});

  final DoctorAssessmentScoreRule rule;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorAssessmentScalesPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${rule.label} · ${rule.minScore}-${rule.maxScore}',
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (rule.suggestion.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rule.suggestion,
              style: TextStyle(
                color: palette.mutedText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailEmptyText extends StatelessWidget {
  const _DetailEmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorAssessmentScalesPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: TextStyle(color: palette.mutedText, fontSize: 14),
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
    final palette = _DoctorAssessmentScalesPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
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
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.mutedText,
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
    final palette = _DoctorAssessmentScalesPalette.of(context);
    return Column(
      children: List<Widget>.generate(
        6,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 92,
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

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _DoctorAssessmentScalesPalette {
  const _DoctorAssessmentScalesPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.primaryText,
    required this.mutedText,
    required this.outline,
  });

  factory _DoctorAssessmentScalesPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _DoctorAssessmentScalesPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      primaryText: scheme.onSurface,
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
          : const Color(0xFF7D828A),
      outline: scheme.outlineVariant,
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color primaryText;
  final Color mutedText;
  final Color outline;
}
