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
      'max_points': 10000,
    },
    {
      'id': 2,
      'level_name': '白银会员',
      'level_code': 'SILVER',
      'min_points': 300,
      'max_points': 100000,
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
