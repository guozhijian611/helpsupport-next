import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../data/me_content_models.dart';

class HonorLevelSpec {
  const HonorLevelSpec({
    required this.levelId,
    required this.level,
    required this.title,
    required this.minPoints,
    required this.targetPoints,
    required this.gradientColors,
    required this.medalColor,
    required this.progressDotColor,
    this.isFinal = false,
  });

  final int levelId;
  final int level;
  final String title;
  final int minPoints;
  final int targetPoints;
  final List<Color> gradientColors;
  final Color medalColor;
  final Color progressDotColor;
  final bool isFinal;
}

class HonorSummaryData {
  const HonorSummaryData({
    required this.levels,
    required this.balance,
    required this.badgeCount,
    required this.currentIndex,
  });

  final List<HonorLevelSpec> levels;
  final int balance;
  final int badgeCount;
  final int currentIndex;

  HonorLevelSpec get currentLevel => levels[currentIndex];

  int get remainingToNext {
    if (currentLevel.isFinal && balance >= currentLevel.targetPoints) {
      return 0;
    }
    return (currentLevel.targetPoints - balance)
        .clamp(0, currentLevel.targetPoints)
        .toInt();
  }

  double get currentProgress => honorLevelProgress(balance, currentLevel);

  bool isCompletedLevel(int index) {
    if (index < currentIndex) {
      return true;
    }
    return currentIndex == levels.length - 1 &&
        index == currentIndex &&
        balance >= levels[index].targetPoints;
  }
}

List<HonorLevelSpec> buildHonorLevels(BuildContext context) {
  final l10n = context.l10n;
  return [
    HonorLevelSpec(
      levelId: 0,
      level: 1,
      title: l10n.meHonorLevelApprentice,
      minPoints: 0,
      targetPoints: 1500,
      gradientColors: const [Color(0xFFB7B7B7), Color(0xFFE2E2E2)],
      medalColor: const Color(0xFFC7C7C7),
      progressDotColor: const Color(0xFFBBBBBB),
    ),
    HonorLevelSpec(
      levelId: 0,
      level: 2,
      title: l10n.meHonorLevelPersistent,
      minPoints: 1500,
      targetPoints: 3000,
      gradientColors: const [Color(0xFFFFD31E), Color(0xFFFFEB6B)],
      medalColor: const Color(0xFFE8C12B),
      progressDotColor: const Color(0xFFFFD94D),
    ),
    HonorLevelSpec(
      levelId: 0,
      level: 3,
      title: l10n.meHonorLevelInspired,
      minPoints: 3000,
      targetPoints: 6000,
      gradientColors: const [Color(0xFF44B6E7), Color(0xFF81D7F4)],
      medalColor: const Color(0xFF45B3DD),
      progressDotColor: const Color(0xFF52C6F2),
    ),
    HonorLevelSpec(
      levelId: 0,
      level: 4,
      title: l10n.meHonorLevelReborn,
      minPoints: 6000,
      targetPoints: 10000,
      gradientColors: const [
        Color(0xFFF3DADB),
        Color(0xFFCC9AE8),
        Color(0xFFB8DAF3),
      ],
      medalColor: const Color(0xFFB793F1),
      progressDotColor: const Color(0xFFD2A6FF),
      isFinal: true,
    ),
  ];
}

HonorSummaryData buildHonorSummary(
  BuildContext context, {
  required int balance,
  required int badgeCount,
  Map<String, dynamic>? member,
}) {
  final levels = _configuredHonorLevels(member) ?? buildHonorLevels(context);
  return HonorSummaryData(
    levels: levels,
    balance: balance,
    badgeCount: badgeCount,
    currentIndex: honorCurrentIndex(levels, balance),
  );
}

int honorCurrentIndex(List<HonorLevelSpec> levels, int balance) {
  if (levels.isEmpty) {
    return 0;
  }
  var currentIndex = 0;
  for (var index = 0; index < levels.length; index += 1) {
    if (balance >= levels[index].minPoints) {
      currentIndex = index;
    }
  }
  return currentIndex;
}

Map<String, dynamic>? honorMemberPayload(
  Map<String, dynamic>? sessionMember,
  Map<String, dynamic>? liveMember,
) {
  if (sessionMember == null || sessionMember.isEmpty) {
    return liveMember;
  }
  if (liveMember == null || liveMember.isEmpty) {
    return sessionMember;
  }
  return <String, dynamic>{...sessionMember, ...liveMember};
}

List<HonorLevelSpec>? _configuredHonorLevels(Map<String, dynamic>? member) {
  final value = member?['member_levels'];
  if (value is! List || value.isEmpty) {
    return null;
  }

  final rows = value
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .where((row) => _intValue(row['id']) > 0)
      .toList();
  if (rows.isEmpty) {
    return null;
  }
  rows.sort(
    (left, right) =>
        _intValue(left['min_points']).compareTo(_intValue(right['min_points'])),
  );

  return [
    for (var index = 0; index < rows.length; index += 1)
      _levelSpecFromConfig(rows, index),
  ];
}

HonorLevelSpec _levelSpecFromConfig(
  List<Map<String, dynamic>> rows,
  int index,
) {
  final row = rows[index];
  final nextRow = index + 1 < rows.length ? rows[index + 1] : null;
  final minPoints = _intValue(row['min_points']);
  final maxPoints = _nullableInt(row['max_points']);
  final nextMinPoints = nextRow == null
      ? null
      : _intValue(nextRow['min_points']);
  final targetPoints = _levelTargetPoints(
    minPoints: minPoints,
    maxPoints: maxPoints,
    nextMinPoints: nextMinPoints,
  );
  final colors = _levelColors(row, index);

  return HonorLevelSpec(
    levelId: _intValue(row['id']),
    level: index + 1,
    title: _stringValue(row['level_name'], fallback: 'Lv.${index + 1}'),
    minPoints: minPoints,
    targetPoints: targetPoints,
    gradientColors: colors.gradient,
    medalColor: colors.medal,
    progressDotColor: colors.dot,
    isFinal: index == rows.length - 1,
  );
}

int _levelTargetPoints({
  required int minPoints,
  required int? maxPoints,
  required int? nextMinPoints,
}) {
  if (nextMinPoints != null && nextMinPoints > minPoints) {
    return nextMinPoints;
  }
  if (maxPoints != null && maxPoints > minPoints) {
    return maxPoints;
  }
  return minPoints;
}

double honorLevelProgress(int balance, HonorLevelSpec level) {
  final span = level.targetPoints - level.minPoints;
  if (span <= 0) {
    return balance >= level.minPoints ? 1 : 0;
  }
  return ((balance - level.minPoints) / span).clamp(0, 1).toDouble();
}

String honorLevelStatus(
  BuildContext context,
  HonorSummaryData summary,
  int index,
) {
  if (index == summary.currentIndex) {
    return context.l10n.meCurrentLevel;
  }
  return summary.isCompletedLevel(index)
      ? context.l10n.meHonorUnlocked
      : context.l10n.meHonorLocked;
}

String honorPointsLabel(
  BuildContext context,
  HonorLevelSpec level,
  int balance,
) {
  if (level.isFinal && balance >= level.targetPoints) {
    return context.l10n.meHonorPointsProgressOpen(balance);
  }
  return context.l10n.meHonorPointsProgress(
    balance.clamp(0, level.targetPoints).toInt(),
    level.targetPoints,
  );
}

String honorHintText(
  BuildContext context,
  HonorSummaryData summary,
  int index,
) {
  final level = summary.levels[index];
  if (index < summary.currentIndex) {
    return context.l10n.meHonorUnlocked;
  }
  if (index == summary.currentIndex) {
    if (level.isFinal) {
      return context.l10n.meHonorFinalHint;
    }
    final remaining = (level.targetPoints - summary.balance)
        .clamp(0, level.targetPoints)
        .toInt();
    return remaining == 0
        ? context.l10n.meHonorUnlocked
        : context.l10n.meHonorNextHint(remaining);
  }

  final remainingToUnlock = (level.minPoints - summary.balance)
      .clamp(0, level.minPoints)
      .toInt();
  return remainingToUnlock == 0
      ? context.l10n.meHonorUnlocked
      : context.l10n.meHonorUnlockHint(remainingToUnlock);
}

List<MemberBadge> latestDistinctBadges(List<MemberBadge> badges) {
  final unique = <String>{};
  final result = <MemberBadge>[];
  for (final badge in badges) {
    final key = badge.badgeCode.trim().isEmpty
        ? '${badge.id}'
        : badge.badgeCode;
    if (unique.add(key)) {
      result.add(badge);
    }
  }
  return result;
}

_LevelColors _levelColors(Map<String, dynamic> row, int index) {
  final code = _stringValue(row['level_code']).toUpperCase();
  if (code.contains('GOLD')) {
    return const _LevelColors(
      gradient: [Color(0xFFFFC85A), Color(0xFFFFE19A)],
      medal: Color(0xFFE8B63B),
      dot: Color(0xFFFFD36B),
    );
  }
  if (code.contains('SILVER')) {
    return const _LevelColors(
      gradient: [Color(0xFFAEB7C2), Color(0xFFE1E6EC)],
      medal: Color(0xFFC1CAD4),
      dot: Color(0xFFD5DCE4),
    );
  }
  if (code.contains('NORMAL')) {
    return const _LevelColors(
      gradient: [Color(0xFFFF9585), Color(0xFFFCB08E)],
      medal: Color(0xFFFFB4A8),
      dot: Color(0xFFFFD1C9),
    );
  }

  const palette = [
    _LevelColors(
      gradient: [Color(0xFFFF9585), Color(0xFFFCB08E)],
      medal: Color(0xFFFFB4A8),
      dot: Color(0xFFFFD1C9),
    ),
    _LevelColors(
      gradient: [Color(0xFF5A81DA), Color(0xFF8FAAF0)],
      medal: Color(0xFF6F91E0),
      dot: Color(0xFFA8BBF5),
    ),
    _LevelColors(
      gradient: [Color(0xFFFFAE4D), Color(0xFFFFD08A)],
      medal: Color(0xFFF4A33D),
      dot: Color(0xFFFFC26E),
    ),
    _LevelColors(
      gradient: [Color(0xFF986FF5), Color(0xFFC2AAFF)],
      medal: Color(0xFFA47EF6),
      dot: Color(0xFFD0BEFF),
    ),
  ];
  return palette[index % palette.length];
}

class _LevelColors {
  const _LevelColors({
    required this.gradient,
    required this.medal,
    required this.dot,
  });

  final List<Color> gradient;
  final Color medal;
  final Color dot;
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse((value ?? '').toString()) ?? fallback;
}

int? _nullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') {
    return null;
  }
  return _intValue(value);
}

String _stringValue(Object? value, {String fallback = ''}) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? fallback : text;
}
