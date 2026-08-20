import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpsupport_app/features/me/data/me_content_models.dart';
import 'package:helpsupport_app/features/me/presentation/honor_badges_support.dart';
import 'package:helpsupport_app/l10n/generated/app_localizations.dart';

void main() {
  const memberLevels = [
    {
      'id': 1,
      'level_name': '普通会员',
      'level_code': 'NORMAL',
      'min_points': 0,
      'max_points': 300,
    },
    {
      'id': 2,
      'level_name': '白银会员',
      'level_code': 'SILVER',
      'min_points': 300,
      'max_points': 1000,
    },
    {
      'id': 3,
      'level_name': '黄金会员',
      'level_code': 'GOLD',
      'min_points': 1000,
      'max_points': 1000000,
    },
  ];

  testWidgets('honor summary follows points, not stored member_level_id', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SizedBox.shrink(),
      ),
    );
    final context = tester.element(find.byType(SizedBox));

    final summary = buildHonorSummary(
      context,
      balance: 500,
      badgeCount: 0,
      member: {
        'member_level_id': 1,
        'member_levels': memberLevels,
      },
    );

    expect(summary.currentLevel.title, '白银会员');
    expect(summary.currentIndex, 1);
    expect(summary.remainingToNext, 500);
    expect(summary.levels[2].targetPoints, 1000000);
  });

  testWidgets('locked cards use this level min and max, not the next card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SizedBox.shrink(),
      ),
    );
    final context = tester.element(find.byType(SizedBox));

    final summary = buildHonorSummary(
      context,
      balance: 130,
      badgeCount: 0,
      member: {
        'member_level_id': 1,
        'member_levels': memberLevels,
      },
    );

    expect(summary.currentLevel.title, '普通会员');
    expect(summary.remainingToNext, 170);
    expect(honorPointsLabel(context, summary.levels[0], 130), '积分 130 / 300');
    expect(honorHintText(context, summary, 0), '距离下一等级还差170积分');
    expect(honorPointsLabel(context, summary.levels[1], 130), '积分 130 / 1000');
    expect(honorHintText(context, summary, 1), '再获得170积分解锁');
    expect(
      honorPointsLabel(context, summary.levels[2], 130),
      '积分 130 / 1000000',
    );
    expect(honorHintText(context, summary, 2), '再获得870积分解锁');
  });

  test('point logs payload can override cached member levels', () {
    final page = PointLogPage.fromJson({
      'list': [],
      'total': 0,
      'page': 1,
      'page_size': 20,
      'balance': 1200,
      'member_level_id': 3,
      'member_level': memberLevels[2],
      'member_levels': memberLevels,
    });

    expect(page.balance, 1200);
    expect(page.member?['member_level_id'], 3);
    expect((page.member?['member_levels'] as List).length, 3);
  });
}
