import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpsupport_app/app/theme.dart';
import 'package:helpsupport_app/core/providers/app_providers.dart';
import 'package:helpsupport_app/core/settings/speech_preferences.dart';
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
  test('chat record parses ai plan task suggestions from ext', () {
    final record = ChatRecord.fromJson(const {
      'id': 10,
      'session_id': 3,
      'chat_mode': 'doctor',
      'role': 'assistant',
      'content': '建议你今天先完成一个小任务。',
      'content_type': 'text',
      'ext':
          '{"plan_tasks":[{"title":"记录情绪波动","description":"写下触发点和应对方式","task_type":"checkin","points_reward":15,"requires_feedback":1,"feedback_prompt":"记录本次应对是否有效"}]}',
    });

    expect(record.planTasks, hasLength(1));
    expect(record.planTasks.first.title, '记录情绪波动');
    expect(record.planTasks.first.requiresFeedback, isTrue);
  });

  test('chat record parses voice and image metadata from ext', () {
    final record = ChatRecord.fromJson(const {
      'id': 11,
      'session_id': 3,
      'chat_mode': 'doctor',
      'role': 'assistant',
      'content': '今天可以先做一次缓慢呼吸。',
      'content_type': 'voice',
      'ext':
          '{"media_url":"/storage/user.m4a","media_mime_type":"audio/mp4","duration_seconds":8,"transcript":"我有点紧张","audio_url":"/storage/chat-ai/reply.mp3","speech_status":"ready"}',
    });

    expect(record.mediaUrl, '/storage/user.m4a');
    expect(record.durationSeconds, 8);
    expect(record.transcript, '我有点紧张');
    expect(record.audioUrl, '/storage/chat-ai/reply.mp3');
    expect(record.speechStatus, 'ready');
    expect(record.displayMediaUrls, ['/storage/user.m4a']);
  });

  test('chat record parses multiple image urls from ext', () {
    final record = ChatRecord.fromJson(const {
      'id': 13,
      'session_id': 3,
      'chat_mode': 'doctor',
      'role': 'user',
      'content': '这几张图里我看起来怎么样？',
      'content_type': 'image',
      'ext':
          '{"attachment_id":11,"attachment_ids":[11,12],"media_url":"/storage/a.jpg","media_urls":["/storage/a.jpg","/storage/b.jpg"]}',
    });

    expect(record.mediaUrl, '/storage/a.jpg');
    expect(record.mediaUrls, ['/storage/a.jpg', '/storage/b.jpg']);
    expect(record.displayMediaUrls, ['/storage/a.jpg', '/storage/b.jpg']);
  });

  test('chat record prefers top-level transcript for voice messages', () {
    final record = ChatRecord.fromJson(const {
      'id': 12,
      'session_id': 3,
      'chat_mode': 'companion',
      'role': 'user',
      'content': '今天可以先做一次缓慢呼吸。',
      'content_type': 'voice',
      'transcript': '我有点紧张',
      'ext': '{"media_url":"/storage/user.m4a"}',
    });

    expect(record.transcript, '我有点紧张');
  });

  test('chat mode info reads locale tags and capability flags', () {
    final mode = ChatModeInfo.fromJson({
      'chat_mode': 'night_companion',
      'prompt_text': '',
      'online_config_id': 0,
      'temp_save': '',
      'allow_online': 1,
      'allow_local': 2,
      'allow_realtime': 2,
      'allow_voice': 1,
      'allow_user_prompt': 2,
      'speech_runtime': 'auto',
      'tags': {
        'zh-CN': ['陪伴', '夜间'],
        'en': ['companion'],
      },
      'robot_profile': {
        'display_name': '夜间陪伴',
        'display_name_en': 'Night companion',
        'description': '安静地陪你',
        'description_en': 'Quiet company',
      },
    });

    expect(mode.allowLocal, isFalse);
    expect(mode.allowUserPrompt, isFalse);
    expect(mode.allowRealtime, isFalse);
    expect(mode.speechRuntime, 'auto');
    expect(mode.tagsFor('zh'), ['陪伴', '夜间']);
    expect(mode.tagsFor('en'), ['companion']);
    expect(mode.robotProfile.displayNameFor('zh'), '夜间陪伴');
  });

  test('speech preference uses role runtime then user priority', () {
    expect(
      useLocalSpeech(
        speechRuntime: 'online',
        priority: SpeechPriority.localFirst,
      ),
      isFalse,
    );
    expect(
      useLocalSpeech(
        speechRuntime: 'local',
        priority: SpeechPriority.onlineFirst,
      ),
      isTrue,
    );
    expect(
      useLocalSpeech(
        speechRuntime: 'auto',
        priority: SpeechPriority.localFirst,
      ),
      isTrue,
    );
    expect(
      useLocalSpeech(
        speechRuntime: 'auto',
        priority: SpeechPriority.onlineFirst,
      ),
      isFalse,
    );
  });

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
                  onlineConfigId: 3,
                  tempSave: '',
                  robotProfile: AiRobotProfile(
                    id: 1,
                    chatMode: 'doctor',
                    runtimeMode: 'online',
                    displayName: 'AI doctor',
                    displayNameEn: 'AI doctor',
                    description: 'Careful support',
                    descriptionEn: 'Careful support',
                    avatar: '',
                    darkAvatar: '',
                  ),
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

  testWidgets('plan screen separates doctor and ai task sources', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
          currentPlansProvider.overrideWith((ref) async => const []),
          dailyTasksByDateProvider.overrideWith(
            (ref, date) async => const PlanPage<DailyTask>(
              list: [
                DailyTask(
                  id: 1,
                  planId: 1,
                  stageId: 1,
                  taskDate: '2026-07-02',
                  startTime: '',
                  endTime: '',
                  title: '医生任务',
                  description: '',
                  taskType: 'daily',
                  source: 'doctor',
                  sourceId: '',
                  reminders: [],
                  attachments: [],
                  pointsReward: 10,
                  completedTime: '',
                  completionNote: '',
                  requiresFeedback: false,
                  feedbackPrompt: '',
                  feedbackContent: '',
                  feedbackTime: '',
                  status: 0,
                ),
                DailyTask(
                  id: 2,
                  planId: 0,
                  stageId: 0,
                  taskDate: '2026-07-02',
                  startTime: '',
                  endTime: '',
                  title: 'AI 任务',
                  description: '',
                  taskType: 'daily',
                  source: 'ai',
                  sourceId: '',
                  reminders: [],
                  attachments: [],
                  pointsReward: 10,
                  completedTime: '',
                  completionNote: '',
                  requiresFeedback: false,
                  feedbackPrompt: '',
                  feedbackContent: '',
                  feedbackTime: '',
                  status: 0,
                ),
              ],
              total: 2,
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
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PlanScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('医生(治疗计划)'), findsOneWidget);
    expect(find.text('AI 添加'), findsOneWidget);
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
