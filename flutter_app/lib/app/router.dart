import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_protocol.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/auth_protocol_screen.dart';
import '../features/auth/presentation/complete_profile_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/appointment/presentation/appointment_doctor_detail_screen.dart';
import '../features/appointment/presentation/appointment_doctor_list_screen.dart';
import '../features/appointment/presentation/appointment_list_screen.dart';
import '../features/chat/presentation/chat_home_screen.dart';
import '../features/chat/presentation/chat_session_screen.dart';
import '../features/community/presentation/community_post_detail_screen.dart';
import '../features/community/presentation/community_post_editor_screen.dart';
import '../features/doctor/presentation/doctor_assessment_scales_screen.dart';
import '../features/doctor/presentation/doctor_patients_screen.dart';
import '../features/doctor/presentation/doctor_plan_screen.dart';
import '../features/doctor/presentation/doctor_task_templates_screen.dart';
import '../features/doctor/presentation/doctor_treatment_plan_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/local_model/presentation/local_model_chat_screen.dart';
import '../features/local_model/presentation/local_model_screen.dart';
import '../features/material/data/material_models.dart';
import '../features/material/presentation/material_detail_screen.dart';
import '../features/material/presentation/material_library_screen.dart';
import '../features/message/presentation/message_center_screen.dart';
import '../features/me/presentation/journal_screen.dart';
import '../features/me/presentation/memoir_screen.dart';
import '../features/me/presentation/settings_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/register/profile',
        name: 'register-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/protocol/:type',
        name: 'protocol',
        builder: (context, state) {
          final type = AuthProtocolType.fromRouteValue(
            state.pathParameters['type'] ?? '',
          );
          return AuthProtocolScreen(type: type ?? AuthProtocolType.terms);
        },
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => HomeShell(
          initialIndex: _homeTabIndex(state.uri.queryParameters['tab']),
        ),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatHomeScreen(),
      ),
      GoRoute(
        path: '/appointments/doctors',
        name: 'appointment-doctors',
        builder: (context, state) => const AppointmentDoctorListScreen(),
      ),
      GoRoute(
        path: '/appointments/doctors/:id',
        name: 'appointment-doctor-detail',
        builder: (context, state) {
          return AppointmentDoctorDetailScreen(
            doctorId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/appointments/mine',
        name: 'appointment-mine',
        builder: (context, state) => const AppointmentListScreen(),
      ),
      GoRoute(
        path: '/chat/session/:id',
        name: 'chat-session',
        builder: (context, state) {
          return ChatSessionScreen(
            sessionId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            chatMode: state.uri.queryParameters['mode'] ?? 'companion',
            title: state.uri.queryParameters['title'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/community/new',
        name: 'community-new',
        builder: (context, state) => const CommunityPostEditorScreen(),
      ),
      GoRoute(
        path: '/community/post/:id',
        name: 'community-post',
        builder: (context, state) {
          return CommunityPostDetailScreen(
            postId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/doctor/plan',
        name: 'doctor-plan',
        builder: (context, state) {
          return DoctorPlanScreen(
            initialMemberId:
                int.tryParse(state.uri.queryParameters['memberId'] ?? '') ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/doctor/treatment-plan',
        name: 'doctor-treatment-plan',
        builder: (context, state) {
          return DoctorTreatmentPlanScreen(
            initialMemberId:
                int.tryParse(state.uri.queryParameters['memberId'] ?? '') ?? 0,
            initialPlanId:
                int.tryParse(state.uri.queryParameters['planId'] ?? '') ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/doctor/patients',
        name: 'doctor-patients',
        builder: (context, state) => const DoctorPatientsScreen(),
      ),
      GoRoute(
        path: '/doctor/task-templates',
        name: 'doctor-task-templates',
        builder: (context, state) => const DoctorTaskTemplatesScreen(),
      ),
      GoRoute(
        path: '/doctor/assessment-scales',
        name: 'doctor-assessment-scales',
        builder: (context, state) => const DoctorAssessmentScalesScreen(),
      ),
      GoRoute(
        path: '/me/messages',
        name: 'me-messages',
        builder: (context, state) => const MessageCenterScreen(),
      ),
      GoRoute(
        path: '/me/settings',
        name: 'me-settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/me/settings/:section',
        name: 'me-settings-detail',
        builder: (context, state) {
          return SettingsDetailScreen(
            section: SettingsSectionType.fromRouteValue(
              state.pathParameters['section'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/me/journals',
        name: 'me-journals',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: '/me/memoirs',
        name: 'me-memoirs',
        builder: (context, state) => const MemoirScreen(),
      ),
      GoRoute(
        path: '/local-model',
        name: 'local-model',
        builder: (context, state) => LocalModelScreen(
          preferredChatMode: state.uri.queryParameters['mode'] ?? '',
          preferredTitle: state.uri.queryParameters['title'] ?? '',
        ),
      ),
      GoRoute(
        path: '/local-model/chat/:id',
        name: 'local-model-chat',
        builder: (context, state) {
          return LocalModelChatScreen(
            modelId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            chatMode: state.uri.queryParameters['mode'] ?? 'companion',
            title: state.uri.queryParameters['title'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/materials',
        name: 'materials',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'education';
          final sourceName = state.uri.queryParameters['source'] ?? 'browse';
          final source = switch (sourceName) {
            'history' => MaterialLibrarySource.history,
            'collections' => MaterialLibrarySource.collections,
            _ => MaterialLibrarySource.browse,
          };
          return MaterialLibraryScreen(materialType: type, source: source);
        },
      ),
      GoRoute(
        path: '/materials/detail/:id',
        name: 'material-detail',
        builder: (context, state) {
          return MaterialDetailScreen(
            materialId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          );
        },
      ),
    ],
  );
});

int _homeTabIndex(String? value) {
  return switch (value) {
    '1' || 'community' => 1,
    '2' || 'plan' => 2,
    '3' || 'me' => 3,
    _ => 0,
  };
}
