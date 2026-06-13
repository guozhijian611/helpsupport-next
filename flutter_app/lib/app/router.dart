import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/chat/presentation/chat_home_screen.dart';
import '../features/chat/presentation/chat_session_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/local_model/presentation/local_model_chat_screen.dart';
import '../features/local_model/presentation/local_model_screen.dart';
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
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatHomeScreen(),
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
        path: '/local-model',
        name: 'local-model',
        builder: (context, state) => const LocalModelScreen(),
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
    ],
  );
});
