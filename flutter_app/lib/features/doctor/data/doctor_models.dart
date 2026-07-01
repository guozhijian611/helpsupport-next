import 'dart:convert';

import '../../plan/data/plan_models.dart';

class DoctorPage<T> {
  const DoctorPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory DoctorPage.fromJson(
    Object? value,
    T Function(Map<String, dynamic> json) decode,
  ) {
    if (value is! Map<String, dynamic>) {
      return const DoctorPage(list: [], total: 0, page: 1, pageSize: 20);
    }

    return DoctorPage<T>(
      list: _list(value['list'], decode),
      total: _intValue(value['total']),
      page: _intValue(value['page'], fallback: 1),
      pageSize: _intValue(value['page_size'], fallback: 20),
    );
  }

  final List<T> list;
  final int total;
  final int page;
  final int pageSize;
}

class DoctorPatient {
  const DoctorPatient({
    required this.id,
    required this.doctorId,
    required this.memberId,
    required this.status,
    required this.bindSource,
    required this.bindTime,
    required this.unbindTime,
    required this.nickname,
    required this.avatar,
    required this.gender,
    required this.birthday,
    required this.recoveryGoal,
    required this.triggerTags,
    required this.locale,
    required this.timezone,
    required this.isBound,
    required this.currentPlanId,
    required this.currentPlanTitle,
    required this.currentStageId,
    required this.currentStageName,
    required this.currentStageStatus,
    required this.currentStageTaskCount,
    required this.currentStageDoneCount,
  });

  factory DoctorPatient.fromJson(Map<String, dynamic> json) {
    return DoctorPatient(
      id: _intValue(json['id']),
      doctorId: _intValue(json['doctor_id']),
      memberId: _intValue(json['member_id']),
      status: _intValue(json['status'], fallback: 1),
      bindSource: _stringValue(json['bind_source']),
      bindTime: _stringValue(json['bind_time']),
      unbindTime: _stringValue(json['unbind_time']),
      nickname: _stringValue(json['nickname']),
      avatar: _stringValue(json['avatar']),
      gender: _stringValue(json['gender']),
      birthday: _stringValue(json['birthday']),
      recoveryGoal: _stringValue(json['recovery_goal']),
      triggerTags: _stringListValue(json['trigger_tags']),
      locale: _stringValue(json['locale']),
      timezone: _stringValue(json['timezone']),
      isBound: _intValue(json['is_bound']) == 1,
      currentPlanId: _intValue(json['current_plan_id']),
      currentPlanTitle: _stringValue(json['current_plan_title']),
      currentStageId: _intValue(json['current_stage_id']),
      currentStageName: _stringValue(json['current_stage_name']),
      currentStageStatus: _intValue(json['current_stage_status']),
      currentStageTaskCount: _intValue(json['current_stage_task_count']),
      currentStageDoneCount: _intValue(json['current_stage_done_count']),
    );
  }

  final int id;
  final int doctorId;
  final int memberId;
  final int status;
  final String bindSource;
  final String bindTime;
  final String unbindTime;
  final String nickname;
  final String avatar;
  final String gender;
  final String birthday;
  final String recoveryGoal;
  final List<String> triggerTags;
  final String locale;
  final String timezone;
  final bool isBound;
  final int currentPlanId;
  final String currentPlanTitle;
  final int currentStageId;
  final String currentStageName;
  final int currentStageStatus;
  final int currentStageTaskCount;
  final int currentStageDoneCount;

  String get displayName => nickname.trim().isEmpty ? '患者' : nickname.trim();

  String get genderLabel {
    final normalized = gender.trim().toLowerCase();
    if (normalized == 'female' || normalized == '2' || normalized == '女') {
      return '女';
    }
    if (normalized == 'private' || normalized == '0' || normalized == '保密') {
      return '保密';
    }
    return '男';
  }

  String get ageLabel {
    final date = DateTime.tryParse(birthday);
    if (date == null) {
      return '--';
    }
    final now = DateTime.now();
    var age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age -= 1;
    }
    return age < 0 ? '--' : '$age';
  }

  DoctorPatient copyWith({String? recoveryGoal, List<String>? triggerTags}) {
    return DoctorPatient(
      id: id,
      doctorId: doctorId,
      memberId: memberId,
      status: status,
      bindSource: bindSource,
      bindTime: bindTime,
      unbindTime: unbindTime,
      nickname: nickname,
      avatar: avatar,
      gender: gender,
      birthday: birthday,
      recoveryGoal: recoveryGoal ?? this.recoveryGoal,
      triggerTags: triggerTags ?? this.triggerTags,
      locale: locale,
      timezone: timezone,
      isBound: isBound,
      currentPlanId: currentPlanId,
      currentPlanTitle: currentPlanTitle,
      currentStageId: currentStageId,
      currentStageName: currentStageName,
      currentStageStatus: currentStageStatus,
      currentStageTaskCount: currentStageTaskCount,
      currentStageDoneCount: currentStageDoneCount,
    );
  }
}

class DoctorTaskTemplateFolder {
  const DoctorTaskTemplateFolder({
    required this.id,
    required this.doctorId,
    required this.name,
    required this.color,
    required this.sort,
    required this.status,
  });

  factory DoctorTaskTemplateFolder.fromJson(Map<String, dynamic> json) {
    return DoctorTaskTemplateFolder(
      id: _stringValue(json['id']),
      doctorId: _intValue(json['doctor_id']),
      name: _stringValue(json['name']),
      color: _stringValue(json['color'], fallback: '#5E8FE6'),
      sort: _intValue(json['sort'], fallback: 100),
      status: _intValue(json['status'], fallback: 1),
    );
  }

  final String id;
  final int doctorId;
  final String name;
  final String color;
  final int sort;
  final int status;
}

class DoctorTaskTemplate {
  const DoctorTaskTemplate({
    required this.id,
    required this.doctorId,
    required this.folderId,
    required this.stage,
    required this.title,
    required this.description,
    required this.taskType,
    required this.priority,
    required this.startTime,
    required this.endTime,
    required this.frequency,
    required this.rewardScore,
    required this.attachments,
    required this.color,
    required this.status,
    required this.createTime,
  });

  factory DoctorTaskTemplate.fromJson(Map<String, dynamic> json) {
    return DoctorTaskTemplate(
      id: _stringValue(json['id']),
      doctorId: _intValue(json['doctor_id']),
      folderId: _stringValue(json['folder_id']),
      stage: _stringValue(json['stage']),
      title: _stringValue(json['title']),
      description: _stringValue(json['description']),
      taskType: _stringValue(json['task_type'], fallback: 'daily'),
      priority: _stringValue(json['priority'], fallback: 'normal'),
      startTime: _stringValue(json['start_time']),
      endTime: _stringValue(json['end_time']),
      frequency: _stringValue(json['frequency']),
      rewardScore: _intValue(json['reward_score']),
      attachments: _dailyTaskAttachments(json['attachments']),
      color: _stringValue(json['color'], fallback: '#5E8FE6'),
      status: _intValue(json['status'], fallback: 1),
      createTime: _stringValue(json['create_time']),
    );
  }

  final String id;
  final int doctorId;
  final String folderId;
  final String stage;
  final String title;
  final String description;
  final String taskType;
  final String priority;
  final String startTime;
  final String endTime;
  final String frequency;
  final int rewardScore;
  final List<DailyTaskAttachment> attachments;
  final String color;
  final int status;
  final String createTime;
}

class DoctorAssessmentScale {
  const DoctorAssessmentScale({
    required this.id,
    required this.doctorId,
    required this.title,
    required this.stage,
    required this.description,
    required this.totalScore,
    required this.questions,
    required this.scoringRule,
    required this.status,
    required this.publishedAt,
    required this.createTime,
  });

  factory DoctorAssessmentScale.fromJson(Map<String, dynamic> json) {
    return DoctorAssessmentScale(
      id: _stringValue(json['id']),
      doctorId: _intValue(json['doctor_id']),
      title: _stringValue(json['title']),
      stage: _stringValue(json['stage']),
      description: _stringValue(json['description']),
      totalScore: _intValue(json['total_score']),
      questions: _mapList(json['questions'], DoctorAssessmentQuestion.fromJson),
      scoringRule: _mapList(
        json['scoring_rule'],
        DoctorAssessmentScoreRule.fromJson,
      ),
      status: _stringValue(json['status'], fallback: 'draft'),
      publishedAt: _stringValue(json['published_at']),
      createTime: _stringValue(json['create_time']),
    );
  }

  final String id;
  final int doctorId;
  final String title;
  final String stage;
  final String description;
  final int totalScore;
  final List<DoctorAssessmentQuestion> questions;
  final List<DoctorAssessmentScoreRule> scoringRule;
  final String status;
  final String publishedAt;
  final String createTime;

  bool get isPublished => status == 'published';
}

class DoctorAssessmentQuestion {
  const DoctorAssessmentQuestion({
    required this.id,
    required this.title,
    required this.options,
  });

  final String id;
  final String title;
  final List<DoctorAssessmentOption> options;

  factory DoctorAssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return DoctorAssessmentQuestion(
      id: _stringValue(json['id']),
      title: _stringValue(json['title']),
      options: _mapList(json['options'], DoctorAssessmentOption.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'options': options.map((item) => item.toJson()).toList(growable: false),
    };
  }

  DoctorAssessmentQuestion copyWith({
    String? id,
    String? title,
    List<DoctorAssessmentOption>? options,
  }) {
    return DoctorAssessmentQuestion(
      id: id ?? this.id,
      title: title ?? this.title,
      options: options ?? this.options,
    );
  }
}

class DoctorAssessmentOption {
  const DoctorAssessmentOption({
    required this.id,
    required this.label,
    required this.score,
  });

  final String id;
  final String label;
  final int score;

  factory DoctorAssessmentOption.fromJson(Map<String, dynamic> json) {
    return DoctorAssessmentOption(
      id: _stringValue(json['id']),
      label: _stringValue(json['label']),
      score: _intValue(json['score']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'score': score};
  }

  DoctorAssessmentOption copyWith({String? id, String? label, int? score}) {
    return DoctorAssessmentOption(
      id: id ?? this.id,
      label: label ?? this.label,
      score: score ?? this.score,
    );
  }
}

class DoctorAssessmentScoreRule {
  const DoctorAssessmentScoreRule({
    required this.label,
    required this.minScore,
    required this.maxScore,
    required this.suggestion,
  });

  final String label;
  final int minScore;
  final int maxScore;
  final String suggestion;

  factory DoctorAssessmentScoreRule.fromJson(Map<String, dynamic> json) {
    return DoctorAssessmentScoreRule(
      label: _stringValue(json['label']),
      minScore: _intValue(json['min_score']),
      maxScore: _intValue(json['max_score']),
      suggestion: _stringValue(json['suggestion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'min_score': minScore,
      'max_score': maxScore,
      'suggestion': suggestion,
    };
  }
}

class DoctorPatientsQuery {
  const DoctorPatientsQuery({
    this.status = 1,
    this.keyword = '',
    this.page = 1,
    this.pageSize = 50,
  });

  final int? status;
  final String keyword;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is DoctorPatientsQuery &&
        other.status == status &&
        other.keyword == keyword &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(status, keyword, page, pageSize);
}

class DoctorPatientCandidatesQuery {
  const DoctorPatientCandidatesQuery({
    this.keyword = '',
    this.page = 1,
    this.pageSize = 10,
  });

  final String keyword;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is DoctorPatientCandidatesQuery &&
        other.keyword == keyword &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(keyword, page, pageSize);
}

class DoctorDailyTasksQuery {
  const DoctorDailyTasksQuery({
    required this.memberId,
    this.date = '',
    this.planId = 0,
  });

  final int memberId;
  final String date;
  final int planId;

  @override
  bool operator ==(Object other) {
    return other is DoctorDailyTasksQuery &&
        other.memberId == memberId &&
        other.date == date &&
        other.planId == planId;
  }

  @override
  int get hashCode => Object.hash(memberId, date, planId);
}

class DoctorAssessmentResultsQuery {
  const DoctorAssessmentResultsQuery({
    required this.memberId,
    this.page = 1,
    this.pageSize = 10,
  });

  final int memberId;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is DoctorAssessmentResultsQuery &&
        other.memberId == memberId &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(memberId, page, pageSize);
}

class DoctorPatientPlansQuery {
  const DoctorPatientPlansQuery({required this.memberId, this.status});

  final int memberId;
  final int? status;

  @override
  bool operator ==(Object other) {
    return other is DoctorPatientPlansQuery &&
        other.memberId == memberId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(memberId, status);
}

class DoctorTaskTemplatesQuery {
  const DoctorTaskTemplatesQuery({
    this.folderId = '',
    this.stage = '',
    this.status = 1,
  });

  final String folderId;
  final String stage;
  final int? status;

  @override
  bool operator ==(Object other) {
    return other is DoctorTaskTemplatesQuery &&
        other.folderId == folderId &&
        other.stage == stage &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(folderId, stage, status);
}

class DoctorAssessmentScalesQuery {
  const DoctorAssessmentScalesQuery({
    this.stage = '',
    this.status = 'published',
  });

  final String stage;
  final String status;

  @override
  bool operator ==(Object other) {
    return other is DoctorAssessmentScalesQuery &&
        other.stage == stage &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(stage, status);
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

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? fallback;
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = '$value'.trim();
  return text.isEmpty ? fallback : text;
}

List<String> _stringListValue(Object? value) {
  if (value is List) {
    return value
        .map((item) => (item ?? '').toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    final normalized = value.trim();
    if (normalized.startsWith('[') && normalized.endsWith(']')) {
      try {
        final decoded = jsonDecode(normalized);
        if (decoded is List) {
          return _stringListValue(decoded);
        }
      } on FormatException {
        return const [];
      }
    }
    return normalized
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

List<DailyTaskAttachment> _dailyTaskAttachments(Object? value) {
  if (value is String) {
    final normalized = value.trim();
    if (normalized.startsWith('[') || normalized.startsWith('{')) {
      try {
        return _dailyTaskAttachments(jsonDecode(normalized));
      } on FormatException {
        return const [];
      }
    }
    return const [];
  }
  if (value is List) {
    return value
        .map(DailyTaskAttachment.fromJson)
        .where((item) => item.displayTitle.isNotEmpty)
        .toList(growable: false);
  }
  if (value is Map) {
    final attachment = DailyTaskAttachment.fromJson(value);
    return attachment.displayTitle.isEmpty ? const [] : [attachment];
  }
  return const [];
}

typedef DoctorDailyTaskPage = PlanPage<DailyTask>;
