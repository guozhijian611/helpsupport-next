class PlanPage<T> {
  const PlanPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> list;
  final int total;
  final int page;
  final int pageSize;

  factory PlanPage.fromJson(
    Object? value,
    T Function(Map<String, dynamic> json) decode,
  ) {
    if (value is! Map<String, dynamic>) {
      return const PlanPage(list: [], total: 0, page: 1, pageSize: 20);
    }

    return PlanPage<T>(
      list: _list(value['list'], decode),
      total: _intValue(value['total']),
      page: _intValue(value['page'], fallback: 1),
      pageSize: _intValue(value['page_size'], fallback: 20),
    );
  }
}

class TreatmentPlan {
  const TreatmentPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.stages,
  });

  final int id;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final int status;
  final List<TreatmentStage> stages;

  factory TreatmentPlan.fromJson(Map<String, dynamic> json) {
    return TreatmentPlan(
      id: _intValue(json['id']),
      title: _stringValue(json['title']),
      description: _stringValue(json['description']),
      startDate: _stringValue(json['start_date']),
      endDate: _stringValue(json['end_date']),
      status: _intValue(json['status']),
      stages: _list(json['stages'], TreatmentStage.fromJson),
    );
  }
}

class TreatmentStage {
  const TreatmentStage({
    required this.id,
    required this.planId,
    required this.stageKey,
    required this.stageName,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.sort,
    required this.status,
  });

  final int id;
  final int planId;
  final String stageKey;
  final String stageName;
  final String startDate;
  final String endDate;
  final String description;
  final int sort;
  final int status;

  factory TreatmentStage.fromJson(Map<String, dynamic> json) {
    return TreatmentStage(
      id: _intValue(json['id']),
      planId: _intValue(json['plan_id']),
      stageKey: _stringValue(json['stage_key']),
      stageName: _stringValue(json['stage_name']),
      startDate: _stringValue(json['start_date']),
      endDate: _stringValue(json['end_date']),
      description: _stringValue(
        json['stage_target'],
        fallback: _stringValue(json['description']),
      ),
      sort: _intValue(json['sort'], fallback: 100),
      status: _intValue(json['status']),
    );
  }
}

class DailyTask {
  const DailyTask({
    required this.id,
    required this.planId,
    required this.stageId,
    required this.taskDate,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.description,
    required this.taskType,
    required this.source,
    required this.sourceId,
    required this.reminders,
    required this.attachments,
    required this.pointsReward,
    required this.completedTime,
    required this.completionNote,
    required this.status,
  });

  final int id;
  final int planId;
  final int stageId;
  final String taskDate;
  final String startTime;
  final String endTime;
  final String title;
  final String description;
  final String taskType;
  final String source;
  final String sourceId;
  final List<String> reminders;
  final List<String> attachments;
  final int pointsReward;
  final String completedTime;
  final String completionNote;
  final int status;

  bool get isDone => status == 1;
  bool get isSkipped => status == 2;

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: _intValue(json['id']),
      planId: _intValue(json['plan_id']),
      stageId: _intValue(json['stage_id']),
      taskDate: _stringValue(json['task_date']),
      startTime: _stringValue(json['start_time']),
      endTime: _stringValue(json['end_time']),
      title: _stringValue(json['title']),
      description: _stringValue(json['description']),
      taskType: _stringValue(json['task_type'], fallback: 'daily'),
      source: _stringValue(json['source'], fallback: 'manual'),
      sourceId: _stringValue(json['source_id']),
      reminders: _stringList(json['reminders']),
      attachments: _stringList(json['attachments']),
      pointsReward: _intValue(json['points_reward']),
      completedTime: _stringValue(json['completed_time']),
      completionNote: _stringValue(json['completion_note']),
      status: _intValue(json['status']),
    );
  }
}

class AssessmentResult {
  const AssessmentResult({
    required this.id,
    required this.assessmentTitle,
    required this.taskTitle,
    required this.questionCount,
    required this.totalScore,
    required this.achievedScore,
    required this.resultLevel,
    required this.suggestions,
    required this.assessedAt,
  });

  final int id;
  final String assessmentTitle;
  final String taskTitle;
  final int questionCount;
  final int totalScore;
  final int achievedScore;
  final String resultLevel;
  final String suggestions;
  final String assessedAt;

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      id: _intValue(json['id']),
      assessmentTitle: _stringValue(json['assessment_title']),
      taskTitle: _stringValue(json['task_title']),
      questionCount: _intValue(json['question_count']),
      totalScore: _intValue(json['total_score']),
      achievedScore: _intValue(json['achieved_score']),
      resultLevel: _stringValue(json['result_level']),
      suggestions: _stringValue(json['suggestions']),
      assessedAt: _stringValue(json['assessed_at']),
    );
  }
}

class AssessmentTaskDetail {
  const AssessmentTaskDetail({
    required this.task,
    required this.scale,
    required this.result,
  });

  final DailyTask task;
  final AssessmentScaleDetail scale;
  final AssessmentResultDetail? result;

  factory AssessmentTaskDetail.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected assessment task detail shape');
    }
    final taskJson = value['task'];
    final scaleJson = value['scale'];
    if (taskJson is! Map<String, dynamic> ||
        scaleJson is! Map<String, dynamic>) {
      throw const FormatException(
        'Assessment task detail missing task or scale',
      );
    }
    final resultJson = value['result'];
    return AssessmentTaskDetail(
      task: DailyTask.fromJson(taskJson),
      scale: AssessmentScaleDetail.fromJson(scaleJson),
      result: resultJson is Map<String, dynamic>
          ? AssessmentResultDetail.fromJson(resultJson)
          : null,
    );
  }
}

class AssessmentScaleDetail {
  const AssessmentScaleDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.totalScore,
    required this.status,
    required this.scoringRule,
    required this.questions,
  });

  final String id;
  final String title;
  final String description;
  final int totalScore;
  final String status;
  final List<AssessmentScoreRule> scoringRule;
  final List<AssessmentQuestion> questions;

  factory AssessmentScaleDetail.fromJson(Map<String, dynamic> json) {
    return AssessmentScaleDetail(
      id: _stringValue(json['id']),
      title: _stringValue(json['title']),
      description: _stringValue(json['description']),
      totalScore: _intValue(json['total_score']),
      status: _stringValue(json['status'], fallback: 'draft'),
      scoringRule: _mapList(json['scoring_rule'], AssessmentScoreRule.fromJson),
      questions: _mapList(json['questions'], AssessmentQuestion.fromJson),
    );
  }
}

class AssessmentScoreRule {
  const AssessmentScoreRule({
    required this.label,
    required this.minScore,
    required this.maxScore,
    required this.suggestion,
  });

  final String label;
  final int minScore;
  final int maxScore;
  final String suggestion;

  factory AssessmentScoreRule.fromJson(Map<String, dynamic> json) {
    return AssessmentScoreRule(
      label: _stringValue(json['label']),
      minScore: _intValue(json['min_score']),
      maxScore: _intValue(json['max_score']),
      suggestion: _stringValue(json['suggestion']),
    );
  }
}

class AssessmentQuestion {
  const AssessmentQuestion({
    required this.id,
    required this.title,
    required this.options,
  });

  final String id;
  final String title;
  final List<AssessmentQuestionOption> options;

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestion(
      id: _stringValue(json['id']),
      title: _stringValue(json['title']),
      options: _mapList(json['options'], AssessmentQuestionOption.fromJson),
    );
  }
}

class AssessmentQuestionOption {
  const AssessmentQuestionOption({
    required this.id,
    required this.label,
    required this.score,
  });

  final String id;
  final String label;
  final int score;

  factory AssessmentQuestionOption.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestionOption(
      id: _stringValue(json['id']),
      label: _stringValue(json['label']),
      score: _intValue(json['score']),
    );
  }
}

class AssessmentResultDetail {
  const AssessmentResultDetail({
    required this.id,
    required this.assessmentId,
    required this.assessmentTitle,
    required this.taskId,
    required this.achievedScore,
    required this.totalScore,
    required this.resultLevel,
    required this.suggestions,
    required this.answers,
  });

  final int id;
  final String assessmentId;
  final String assessmentTitle;
  final int taskId;
  final int achievedScore;
  final int totalScore;
  final String resultLevel;
  final String suggestions;
  final List<AssessmentAnswer> answers;

  factory AssessmentResultDetail.fromJson(Map<String, dynamic> json) {
    return AssessmentResultDetail(
      id: _intValue(json['id']),
      assessmentId: _stringValue(json['assessment_id']),
      assessmentTitle: _stringValue(json['assessment_title']),
      taskId: _intValue(json['task_id']),
      achievedScore: _intValue(json['achieved_score']),
      totalScore: _intValue(json['total_score']),
      resultLevel: _stringValue(json['result_level']),
      suggestions: _stringValue(json['suggestions']),
      answers: _mapList(json['answers'], AssessmentAnswer.fromJson),
    );
  }
}

class AssessmentAnswer {
  const AssessmentAnswer({
    required this.questionId,
    required this.questionTitle,
    required this.optionId,
    required this.optionLabel,
    required this.score,
  });

  final String questionId;
  final String questionTitle;
  final String optionId;
  final String optionLabel;
  final int score;

  factory AssessmentAnswer.fromJson(Map<String, dynamic> json) {
    return AssessmentAnswer(
      questionId: _stringValue(json['question_id']),
      questionTitle: _stringValue(json['question_title']),
      optionId: _stringValue(json['option_id']),
      optionLabel: _stringValue(json['option_label']),
      score: _intValue(json['score']),
    );
  }
}

List<T> _list<T>(Object? value, T Function(Map<String, dynamic> json) decode) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(decode)
      .toList(growable: false);
}

List<T> _mapList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) decode,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .map(decode)
      .toList(growable: false);
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.map((item) => item.toString()).toList(growable: false);
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}
