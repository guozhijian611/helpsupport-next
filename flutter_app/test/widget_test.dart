import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpsupport_app/app/theme.dart';
import 'package:helpsupport_app/core/providers/app_providers.dart';
import 'package:helpsupport_app/features/auth/application/auth_controller.dart';
import 'package:helpsupport_app/features/auth/data/auth_models.dart';
import 'package:helpsupport_app/features/chat/application/chat_controller.dart';
import 'package:helpsupport_app/features/chat/data/chat_models.dart';
import 'package:helpsupport_app/features/community/application/community_controller.dart';
import 'package:helpsupport_app/features/community/data/community_models.dart';
import 'package:helpsupport_app/features/home/presentation/home_shell.dart';
import 'package:helpsupport_app/features/me/application/me_content_controller.dart';
import 'package:helpsupport_app/features/me/data/me_content_models.dart';
import 'package:helpsupport_app/features/me/presentation/me_screen.dart';
import 'package:helpsupport_app/features/plan/application/plan_controller.dart';
import 'package:helpsupport_app/features/plan/data/plan_models.dart';
import 'package:helpsupport_app/features/plan/presentation/plan_screen.dart';
import 'package:helpsupport_app/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home shell renders bottom navigation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          authControllerProvider.overrideWith(_TestAuthController.new),
          chatOverviewProvider.overrideWith(
            (ref) async => const ChatOverview(
              modes: [
                ChatModeInfo(
                  chatMode: 'doctor',
                  promptText: 'Prepare questions',
                  sessionCount: 1,
                ),
              ],
              recentSessions: [
                ChatSession(
                  id: 1,
                  chatMode: 'doctor',
                  sessionName: 'First session',
                  lastMessage: 'Hello',
                  isPinned: false,
                ),
              ],
            ),
          ),
          currentPlansProvider.overrideWith(
            (ref) async => const [
              TreatmentPlan(
                id: 1,
                title: 'Recovery plan',
                description: 'Stay steady',
                startDate: '2026-06-01',
                endDate: '2026-06-30',
                status: 1,
                stages: [],
              ),
            ],
          ),
          communityPostsProvider.overrideWith(
            (ref) async => const CommunityPage(
              list: [
                CommunityPost(
                  id: 1,
                  memberId: 2,
                  content: 'Community check-in',
                  images: [],
                  linkUrl: '',
                  tags: ['support'],
                  authorName: 'A member',
                  authorAvatar: '',
                  isAnonymous: false,
                  isDoctorPost: false,
                  viewCount: 1,
                  likeCount: 2,
                  commentCount: 3,
                  collectCount: 4,
                  isTop: false,
                  auditStatus: 1,
                  createTime: '2026-06-15 10:00:00',
                  isLiked: false,
                  isCollected: false,
                  isFollowedAuthor: false,
                  isMutualFollowAuthor: false,
                ),
              ],
              total: 1,
              page: 1,
              pageSize: 20,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeShell(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Book now'), findsOneWidget);
    expect(find.text('Learning'), findsOneWidget);
  });

  testWidgets('plan calendar toggle expands month calendar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
          currentPlansProvider.overrideWith(
            (ref) async => const [
              TreatmentPlan(
                id: 1,
                title: 'Recovery plan',
                description: 'Stay steady',
                startDate: '2026-06-01',
                endDate: '2026-06-30',
                status: 1,
                stages: [],
              ),
            ],
          ),
          dailyTasksByDateProvider.overrideWith(
            (ref, date) async => const PlanPage<DailyTask>(
              list: [],
              total: 0,
              page: 1,
              pageSize: 50,
            ),
          ),
          assessmentResultsProvider.overrideWith(
            (ref) async => const PlanPage<AssessmentResult>(
              list: [],
              total: 0,
              page: 1,
              pageSize: 10,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PlanScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan-month-calendar')), findsNothing);
    expect(find.byKey(const Key('plan-week-strip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('plan-calendar-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan-month-calendar')), findsOneWidget);
    expect(find.byKey(const Key('plan-week-strip')), findsNothing);
  });

  testWidgets('me screen renders json trigger tags as plain text', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TriggerTagsAuthController.new),
          memberBadgesProvider.overrideWith(
            (ref) async => const MePage<MemberBadge>(
              list: [],
              total: 0,
              page: 1,
              pageSize: 20,
            ),
          ),
          pointLogsProvider.overrideWith(
            (ref) async => const PointLogPage(
              list: [],
              total: 0,
              page: 1,
              pageSize: 20,
              balance: 0,
            ),
          ),
          currentPlansProvider.overrideWith((ref) async => const []),
          dailyTasksProvider.overrideWith(
            (ref) async => const PlanPage<DailyTask>(
              list: [],
              total: 0,
              page: 1,
              pageSize: 20,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: MeScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('睡眠障碍 焦虑'), findsOneWidget);
    expect(find.textContaining('["'), findsNothing);
  });
}

class _TestAuthController extends AuthController {
  @override
  Future<AuthSession?> build() async {
    return const AuthSession(
      token: AuthToken(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
      ),
      member: {'id': 1, 'username': 'tester'},
      profile: {},
      doctorProfile: {},
      currentRole: 'patient',
      roleFlags: AuthRoleFlags(
        profileRole: 'patient',
        isPatient: true,
        isDoctor: false,
        doctorProfileSubmitted: false,
        doctorApproved: false,
      ),
    );
  }
}

class _TriggerTagsAuthController extends AuthController {
  @override
  Future<AuthSession?> build() async {
    return const AuthSession(
      token: AuthToken(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
      ),
      member: {'id': 1, 'username': 'tester'},
      profile: {
        'nickname': 'reused',
        'gender': '1',
        'trigger_tags': '["睡眠障碍","焦虑"]',
      },
      doctorProfile: {},
      currentRole: 'patient',
      roleFlags: AuthRoleFlags(
        profileRole: 'patient',
        isPatient: true,
        isDoctor: false,
        doctorProfileSubmitted: false,
        doctorApproved: false,
      ),
    );
  }
}
