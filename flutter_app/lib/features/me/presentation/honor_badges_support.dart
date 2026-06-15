import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../data/me_content_models.dart';

class HonorLevelSpec {
  const HonorLevelSpec({
    required this.level,
    required this.title,
    required this.targetPoints,
    required this.gradientColors,
    required this.medalColor,
    required this.progressDotColor,
    this.isFinal = false,
  });

  final int level;
  final String title;
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
      level: 1,
      title: l10n.meHonorLevelApprentice,
      targetPoints: 1500,
      gradientColors: const [Color(0xFFB7B7B7), Color(0xFFE2E2E2)],
      medalColor: const Color(0xFFC7C7C7),
      progressDotColor: const Color(0xFFBBBBBB),
    ),
    HonorLevelSpec(
      level: 2,
      title: l10n.meHonorLevelPersistent,
      targetPoints: 3000,
      gradientColors: const [Color(0xFFFFD31E), Color(0xFFFFEB6B)],
      medalColor: const Color(0xFFE8C12B),
      progressDotColor: const Color(0xFFFFD94D),
    ),
    HonorLevelSpec(
      level: 3,
      title: l10n.meHonorLevelInspired,
      targetPoints: 6000,
      gradientColors: const [Color(0xFF44B6E7), Color(0xFF81D7F4)],
      medalColor: const Color(0xFF45B3DD),
      progressDotColor: const Color(0xFF52C6F2),
    ),
    HonorLevelSpec(
      level: 4,
      title: l10n.meHonorLevelReborn,
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
}) {
  final levels = buildHonorLevels(context);
  var currentIndex = levels.length - 1;
  for (var index = 0; index < levels.length; index += 1) {
    if (balance < levels[index].targetPoints) {
      currentIndex = index;
      break;
    }
  }
  return HonorSummaryData(
    levels: levels,
    balance: balance,
    badgeCount: badgeCount,
    currentIndex: currentIndex,
  );
}

double honorLevelProgress(int balance, HonorLevelSpec level) {
  if (level.targetPoints <= 0) {
    return 0;
  }
  return (balance / level.targetPoints).clamp(0, 1).toDouble();
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
  if (level.isFinal && summary.balance >= level.targetPoints) {
    return context.l10n.meHonorFinalHint;
  }
  final remaining = (level.targetPoints - summary.balance)
      .clamp(0, level.targetPoints)
      .toInt();
  return remaining == 0
      ? context.l10n.meHonorUnlocked
      : context.l10n.meHonorNextHint(remaining);
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
