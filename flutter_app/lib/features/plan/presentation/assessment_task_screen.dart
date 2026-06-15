import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/centered_notice.dart';
import '../application/plan_controller.dart';
import '../data/plan_models.dart';

class AssessmentTaskScreen extends ConsumerStatefulWidget {
  const AssessmentTaskScreen({super.key, required this.taskId});

  final int taskId;

  @override
  ConsumerState<AssessmentTaskScreen> createState() =>
      _AssessmentTaskScreenState();
}

class _AssessmentTaskScreenState extends ConsumerState<AssessmentTaskScreen> {
  final Map<String, String> _selectedOptions = <String, String>{};
  int _initializedTaskId = 0;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(assessmentTaskDetailProvider(widget.taskId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: Text(_t(context, '评估量表', 'Assessment')),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _submitting
                ? null
                : () {
                    final data = detail.asData?.value;
                    if (data != null) {
                      _submit(data);
                    }
                  },
            child: Text(_t(context, '完成', 'Done')),
          ),
        ],
      ),
      body: SafeArea(
        child: detail.when(
          data: (item) {
            _hydrateSelection(item);
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Center(
                    child: Text(
                      item.scale.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF303236),
                        fontSize: 23,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (item.scale.description.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Text(
                      item.scale.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8C919A),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                for (
                  var index = 0;
                  index < item.scale.questions.length;
                  index++
                )
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _QuestionCard(
                      index: index,
                      question: item.scale.questions[index],
                      selectedOptionId:
                          _selectedOptions[item.scale.questions[index].id] ??
                          '',
                      onSelect: (optionId) {
                        setState(() {
                          _selectedOptions[item.scale.questions[index].id] =
                              optionId;
                        });
                      },
                    ),
                  ),
                if (_submitting)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8C919A)),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  void _hydrateSelection(AssessmentTaskDetail detail) {
    if (_initializedTaskId == detail.task.id) {
      return;
    }
    _initializedTaskId = detail.task.id;
    _selectedOptions
      ..clear()
      ..addEntries(
        (detail.result?.answers ?? const <AssessmentAnswer>[]).map(
          (item) => MapEntry(item.questionId, item.optionId),
        ),
      );
  }

  Future<void> _submit(AssessmentTaskDetail detail) async {
    if (_submitting) {
      return;
    }
    for (final question in detail.scale.questions) {
      if ((_selectedOptions[question.id] ?? '').isEmpty) {
        context.showCenteredNotice(
          _t(context, '请先完成所有题目', 'Please answer all questions'),
        );
        return;
      }
    }

    final answers = <Map<String, dynamic>>[];
    var achievedScore = 0;
    for (final question in detail.scale.questions) {
      final optionId = _selectedOptions[question.id] ?? '';
      final option = question.options.firstWhere(
        (item) => item.id == optionId,
        orElse: () => question.options.first,
      );
      achievedScore += option.score;
      answers.add({
        'question_id': question.id,
        'question_title': question.title,
        'option_id': option.id,
        'option_label': option.label,
        'score': option.score,
      });
    }
    final matchedRule = _matchScoreRule(detail.scale, achievedScore);
    final level =
        matchedRule?.label ??
        _resultLevel(context, achievedScore, detail.scale.totalScore);
    final suggestion =
        matchedRule?.suggestion ??
        _resultSuggestion(context, achievedScore, detail.scale.totalScore);

    setState(() => _submitting = true);
    try {
      await ref
          .read(planRepositoryProvider)
          .saveAssessmentResult(
            taskId: detail.task.id,
            assessmentId: detail.scale.id,
            assessmentTitle: detail.scale.title,
            questionCount: detail.scale.questions.length,
            totalScore: detail.scale.totalScore,
            achievedScore: achievedScore,
            answers: answers,
            assessmentSnapshot: {
              'id': detail.scale.id,
              'title': detail.scale.title,
              'description': detail.scale.description,
              'total_score': detail.scale.totalScore,
              'questions': detail.scale.questions
                  .map(
                    (item) => {
                      'id': item.id,
                      'title': item.title,
                      'options': item.options
                          .map(
                            (option) => {
                              'id': option.id,
                              'label': option.label,
                              'score': option.score,
                            },
                          )
                          .toList(growable: false),
                    },
                  )
                  .toList(growable: false),
            },
            resultLevel: level,
            suggestions: suggestion,
          );
      await ref
          .read(planRepositoryProvider)
          .updateTaskStatus(taskId: detail.task.id, status: 1);
      ref.invalidate(assessmentTaskDetailProvider(widget.taskId));
      ref.invalidate(assessmentResultsProvider);
      ref.invalidate(dailyTasksProvider);
      ref.invalidate(dailyTasksByDateProvider);
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(_t(context, '量表已提交', 'Assessment submitted'));
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selectedOptionId,
    required this.onSelect,
  });

  final int index;
  final AssessmentQuestion question;
  final String selectedOptionId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${question.title}',
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = ((constraints.maxWidth - 36) / 3).clamp(
                110.0,
                constraints.maxWidth,
              );
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  for (final option in question.options)
                    _OptionTile(
                      option: option,
                      selected: selectedOptionId == option.id,
                      width: width,
                      onTap: () => onSelect(option.id),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final AssessmentQuestionOption option;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF5A81DA) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF5A81DA)
                      : const Color(0xFFB0B3BA),
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 22,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: const TextStyle(
                  color: Color(0xFF8C919A),
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

AssessmentScoreRule? _matchScoreRule(
  AssessmentScaleDetail scale,
  int achievedScore,
) {
  for (final rule in scale.scoringRule) {
    if (achievedScore >= rule.minScore && achievedScore <= rule.maxScore) {
      return rule;
    }
  }
  return null;
}

String _resultLevel(BuildContext context, int achievedScore, int totalScore) {
  if (totalScore <= 0) {
    return '';
  }
  final ratio = achievedScore / totalScore;
  if (ratio >= 0.7) {
    return _t(context, '高风险', 'High risk');
  }
  if (ratio >= 0.4) {
    return _t(context, '中度波动', 'Moderate');
  }
  return _t(context, '轻度波动', 'Mild');
}

String _resultSuggestion(
  BuildContext context,
  int achievedScore,
  int totalScore,
) {
  if (totalScore <= 0) {
    return '';
  }
  final ratio = achievedScore / totalScore;
  if (ratio >= 0.7) {
    return _t(
      context,
      '建议尽快和医生或治疗师复盘当前状态，并及时调整治疗计划。',
      'Review your current condition with your doctor or therapist as soon as possible.',
    );
  }
  if (ratio >= 0.4) {
    return _t(
      context,
      '建议保持规律记录和复测，观察近期情绪与睡眠波动。',
      'Keep a regular record and monitor recent mood and sleep changes.',
    );
  }
  return _t(
    context,
    '当前状态相对稳定，继续保持现有治疗节奏即可。',
    'Your current state looks stable. Keep following the current plan.',
  );
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
