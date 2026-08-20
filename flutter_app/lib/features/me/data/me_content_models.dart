import 'dart:convert';

class MePage<T> {
  const MePage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> list;
  final int total;
  final int page;
  final int pageSize;

  factory MePage.fromJson(
    Object? value,
    T Function(Map<String, dynamic> json) decode,
  ) {
    if (value is! Map<String, dynamic>) {
      return const MePage(list: [], total: 0, page: 1, pageSize: 20);
    }

    return MePage<T>(
      list: _list(value['list'], decode),
      total: _intValue(value['total']),
      page: _intValue(value['page'], fallback: 1),
      pageSize: _intValue(value['page_size'], fallback: 20),
    );
  }
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.memberId,
    required this.entryDate,
    required this.entryTime,
    required this.title,
    required this.content,
    required this.media,
    required this.moodScore,
    required this.isPrivate,
    required this.aiAccess,
    required this.createTime,
  });

  final int id;
  final int memberId;
  final String entryDate;
  final String entryTime;
  final String title;
  final String content;
  final List<String> media;
  final int moodScore;
  final bool isPrivate;
  final bool aiAccess;
  final String createTime;

  String get entryDateTimeLabel {
    if (entryTime.trim().isEmpty) {
      return entryDate;
    }
    return '$entryDate  $entryTime';
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final localId = _intValue(json['local_id']);
    return JournalEntry(
      id: localId > 0 ? localId : _intValue(json['id']),
      memberId: _intValue(json['member_id']),
      entryDate: _stringValue(json['entry_date']),
      entryTime: _stringValue(json['entry_time']),
      title: _stringValue(json['title']),
      content: _stringValue(json['content']),
      media: _stringList(json['media']),
      moodScore: _intValue(json['mood_score']),
      isPrivate: _boolValue(json['is_private'], trueValue: 1),
      aiAccess: _boolValue(json['ai_access'], trueValue: 1),
      createTime: _stringValue(json['create_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'entry_date': entryDate,
      'entry_time': entryTime,
      'title': title,
      'content': content,
      'media': media,
      'mood_score': moodScore,
      'is_private': isPrivate ? 1 : 2,
      'ai_access': aiAccess ? 1 : 2,
      'create_time': createTime,
    };
  }

  JournalEntry copyWith({
    int? id,
    int? memberId,
    String? entryDate,
    String? entryTime,
    String? title,
    String? content,
    List<String>? media,
    int? moodScore,
    bool? isPrivate,
    bool? aiAccess,
    String? createTime,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      entryDate: entryDate ?? this.entryDate,
      entryTime: entryTime ?? this.entryTime,
      title: title ?? this.title,
      content: content ?? this.content,
      media: media ?? this.media,
      moodScore: moodScore ?? this.moodScore,
      isPrivate: isPrivate ?? this.isPrivate,
      aiAccess: aiAccess ?? this.aiAccess,
      createTime: createTime ?? this.createTime,
    );
  }
}

class MemoirItem {
  const MemoirItem({
    required this.id,
    required this.memberId,
    required this.grantLevelId,
    required this.grantLevelRank,
    required this.grantLevelName,
    required this.title,
    required this.description,
    required this.cover,
    required this.videoUrl,
    required this.sourceMonth,
    required this.journalCount,
    required this.materialCount,
    required this.sourceMaterials,
    required this.createTime,
  });

  final int id;
  final int memberId;
  final int grantLevelId;
  final int grantLevelRank;
  final String grantLevelName;
  final String title;
  final String description;
  final String cover;
  final String videoUrl;
  final String sourceMonth;
  final int journalCount;
  final int materialCount;
  final Map<String, dynamic> sourceMaterials;
  final String createTime;

  factory MemoirItem.fromJson(Map<String, dynamic> json) {
    return MemoirItem(
      id: _intValue(json['id']),
      memberId: _intValue(json['member_id']),
      grantLevelId: _intValue(json['grant_level_id']),
      grantLevelRank: _intValue(json['grant_level_rank']),
      grantLevelName: _stringValue(json['grant_level_name']),
      title: _stringValue(json['title']),
      description: _stringValue(json['description']),
      cover: _stringValue(json['cover']),
      videoUrl: _stringValue(json['video_url']),
      sourceMonth: _stringValue(json['source_month']),
      journalCount: _intValue(json['journal_count']),
      materialCount: _intValue(json['material_count']),
      sourceMaterials: _jsonMap(json['source_materials']),
      createTime: _stringValue(json['create_time']),
    );
  }
}

class MemoirConfig {
  const MemoirConfig({
    required this.id,
    required this.name,
    required this.code,
    required this.triggerMode,
    required this.levelStep,
    required this.generationCycle,
    required this.sourceType,
    required this.materialSources,
    required this.promptTemplate,
    required this.minJournalCount,
    required this.minMaterialCount,
    required this.startDay,
    required this.sort,
    required this.canGenerate,
    required this.reason,
    required this.targetLevelName,
    required this.existingMemoirId,
    required this.materialCount,
  });

  final int id;
  final String name;
  final String code;
  final String triggerMode;
  final int levelStep;
  final String generationCycle;
  final String sourceType;
  final List<String> materialSources;
  final String promptTemplate;
  final int minJournalCount;
  final int minMaterialCount;
  final int startDay;
  final int sort;
  final bool canGenerate;
  final String reason;
  final String targetLevelName;
  final int existingMemoirId;
  final int materialCount;

  factory MemoirConfig.fromJson(Map<String, dynamic> json) {
    return MemoirConfig(
      id: _intValue(json['id']),
      name: _stringValue(json['name']),
      code: _stringValue(json['code']),
      triggerMode: _stringValue(json['trigger_mode'], fallback: 'level_up'),
      levelStep: _intValue(json['level_step'], fallback: 1),
      generationCycle: _stringValue(json['generation_cycle']),
      sourceType: _stringValue(json['source_type']),
      materialSources: _stringList(json['material_sources']),
      promptTemplate: _stringValue(json['prompt_template']),
      minJournalCount: _intValue(json['min_journal_count']),
      minMaterialCount: _intValue(json['min_material_count']),
      startDay: _intValue(json['start_day']),
      sort: _intValue(json['sort']),
      canGenerate: _boolValue(json['can_generate']),
      reason: _stringValue(json['reason']),
      targetLevelName: _stringValue(_jsonMap(json['target_level'])['name']),
      existingMemoirId: _intValue(json['existing_memoir_id']),
      materialCount: _intValue(json['material_count']),
    );
  }
}

class MemberBadge {
  const MemberBadge({
    required this.id,
    required this.memberId,
    required this.ruleId,
    required this.badgeCode,
    required this.badgeName,
    required this.badgeIcon,
    required this.badgeDescription,
    required this.sourceType,
    required this.sourceId,
    required this.awardTime,
    required this.ruleTriggerType,
    required this.ruleTriggerValue,
    required this.rulePointsReward,
    required this.status,
  });

  final int id;
  final int memberId;
  final int ruleId;
  final String badgeCode;
  final String badgeName;
  final String badgeIcon;
  final String badgeDescription;
  final String sourceType;
  final int sourceId;
  final String awardTime;
  final String ruleTriggerType;
  final int ruleTriggerValue;
  final int rulePointsReward;
  final int status;

  factory MemberBadge.fromJson(Map<String, dynamic> json) {
    return MemberBadge(
      id: _intValue(json['id']),
      memberId: _intValue(json['member_id']),
      ruleId: _intValue(json['rule_id']),
      badgeCode: _stringValue(json['badge_code']),
      badgeName: _stringValue(json['badge_name']),
      badgeIcon: _stringValue(json['badge_icon']),
      badgeDescription: _stringValue(json['badge_description']),
      sourceType: _stringValue(json['source_type']),
      sourceId: _intValue(json['source_id']),
      awardTime: _stringValue(json['award_time']),
      ruleTriggerType: _stringValue(json['rule_trigger_type']),
      ruleTriggerValue: _intValue(json['rule_trigger_value']),
      rulePointsReward: _intValue(json['rule_points_reward']),
      status: _intValue(json['status'], fallback: 1),
    );
  }
}

class PointLogItem {
  const PointLogItem({
    required this.id,
    required this.memberId,
    required this.points,
    required this.changeType,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.remark,
    required this.balanceAfter,
    required this.createTime,
  });

  final int id;
  final int memberId;
  final int points;
  final String changeType;
  final String sourceType;
  final int sourceId;
  final String title;
  final String remark;
  final int balanceAfter;
  final String createTime;

  bool get isIncome => points >= 0;

  factory PointLogItem.fromJson(Map<String, dynamic> json) {
    return PointLogItem(
      id: _intValue(json['id']),
      memberId: _intValue(json['member_id']),
      points: _intValue(json['points']),
      changeType: _stringValue(json['change_type']),
      sourceType: _stringValue(json['source_type']),
      sourceId: _intValue(json['source_id']),
      title: _stringValue(json['title']),
      remark: _stringValue(json['remark']),
      balanceAfter: _intValue(json['balance_after']),
      createTime: _stringValue(json['create_time']),
    );
  }
}

class PointLogPage {
  const PointLogPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.balance,
  });

  final List<PointLogItem> list;
  final int total;
  final int page;
  final int pageSize;
  final int balance;

  factory PointLogPage.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const PointLogPage(
        list: [],
        total: 0,
        page: 1,
        pageSize: 20,
        balance: 0,
      );
    }

    return PointLogPage(
      list: _list(value['list'], PointLogItem.fromJson),
      total: _intValue(value['total']),
      page: _intValue(value['page'], fallback: 1),
      pageSize: _intValue(value['page_size'], fallback: 20),
      balance: _intValue(value['balance']),
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

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    final normalized = value.trim();
    final decoded = _jsonValue(normalized);
    if (decoded is List) {
      return decoded.map((item) => item.toString()).toList(growable: false);
    }
    return [normalized];
  }
  return const [];
}

Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  final decoded = _jsonValue(value);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

Object? _jsonValue(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  try {
    return jsonDecode(value);
  } catch (_) {
    return null;
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
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

bool _boolValue(Object? value, {int trueValue = 1}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value.toInt() == trueValue;
  }
  if (value is String) {
    return value == '$trueValue' || value.toLowerCase() == 'true';
  }
  return false;
}
