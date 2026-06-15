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
    required this.description,
    required this.sort,
    required this.status,
  });

  final int id;
  final int planId;
  final String stageKey;
  final String stageName;
  final String description;
  final int sort;
  final int status;

  factory TreatmentStage.fromJson(Map<String, dynamic> json) {
    return TreatmentStage(
      id: _intValue(json['id']),
      planId: _intValue(json['plan_id']),
      stageKey: _stringValue(json['stage_key']),
      stageName: _stringValue(json['stage_name']),
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
    required this.taskDate,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.description,
    required this.taskType,
    required this.source,
    required this.pointsReward,
    required this.completedTime,
    required this.completionNote,
    required this.status,
  });

  final int id;
  final int planId;
  final String taskDate;
  final String startTime;
  final String endTime;
  final String title;
  final String description;
  final String taskType;
  final String source;
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
      taskDate: _stringValue(json['task_date']),
      startTime: _stringValue(json['start_time']),
      endTime: _stringValue(json['end_time']),
      title: _stringValue(json['title']),
      description: _stringValue(json['description']),
      taskType: _stringValue(json['task_type'], fallback: 'daily'),
      source: _stringValue(json['source'], fallback: 'manual'),
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

List<T> _list<T>(Object? value, T Function(Map<String, dynamic> json) decode) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(decode)
      .toList(growable: false);
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
