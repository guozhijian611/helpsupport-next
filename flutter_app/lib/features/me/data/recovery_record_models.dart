class RecoveryRecordPage<T> {
  const RecoveryRecordPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> list;
  final int total;
  final int page;
  final int pageSize;

  factory RecoveryRecordPage.fromJson(
    Object? value,
    T Function(Map<String, dynamic> json) decode,
  ) {
    if (value is! Map<String, dynamic>) {
      return const RecoveryRecordPage(
        list: [],
        total: 0,
        page: 1,
        pageSize: 20,
      );
    }

    return RecoveryRecordPage<T>(
      list: _recordList(value['list'], decode),
      total: _recordInt(value['total']),
      page: _recordInt(value['page'], fallback: 1),
      pageSize: _recordInt(value['page_size'], fallback: 20),
    );
  }
}

class RecoveryGoalRecord {
  const RecoveryGoalRecord({
    required this.id,
    required this.memberId,
    required this.goalText,
    required this.goalType,
    required this.targetDate,
    required this.completedTime,
    required this.status,
    required this.remark,
    required this.createTime,
  });

  factory RecoveryGoalRecord.fromJson(Map<String, dynamic> json) {
    return RecoveryGoalRecord(
      id: _recordInt(json['id']),
      memberId: _recordInt(json['member_id']),
      goalText: _recordString(json['goal_text']),
      goalType: _recordString(json['goal_type'], fallback: 'custom'),
      targetDate: _recordString(json['target_date']),
      completedTime: _recordString(json['completed_time']),
      status: _recordInt(json['status'], fallback: 1),
      remark: _recordString(json['remark']),
      createTime: _recordString(json['create_time']),
    );
  }

  final int id;
  final int memberId;
  final String goalText;
  final String goalType;
  final String targetDate;
  final String completedTime;
  final int status;
  final String remark;
  final String createTime;

  bool get isActive => status == 1;
  bool get isCompleted => status == 2;
}

class TriggerLogRecord {
  const TriggerLogRecord({
    required this.id,
    required this.memberId,
    required this.triggerName,
    required this.triggerType,
    required this.intensity,
    required this.occurredAt,
    required this.responseAction,
    required this.note,
    required this.status,
    required this.remark,
    required this.createTime,
  });

  factory TriggerLogRecord.fromJson(Map<String, dynamic> json) {
    return TriggerLogRecord(
      id: _recordInt(json['id']),
      memberId: _recordInt(json['member_id']),
      triggerName: _recordString(json['trigger_name']),
      triggerType: _recordString(json['trigger_type'], fallback: 'custom'),
      intensity: _recordInt(json['intensity']),
      occurredAt: _recordString(json['occurred_at']),
      responseAction: _recordString(json['response_action']),
      note: _recordString(json['note']),
      status: _recordInt(json['status'], fallback: 1),
      remark: _recordString(json['remark']),
      createTime: _recordString(json['create_time']),
    );
  }

  final int id;
  final int memberId;
  final String triggerName;
  final String triggerType;
  final int intensity;
  final String occurredAt;
  final String responseAction;
  final String note;
  final int status;
  final String remark;
  final String createTime;
}

List<T> _recordList<T>(
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

int _recordInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('${value ?? ''}') ?? fallback;
}

String _recordString(Object? value, {String fallback = ''}) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty || text == 'null' ? fallback : text;
}
