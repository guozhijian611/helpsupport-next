import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/chat_models.dart';
import '../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiClientProvider));
});

final chatOverviewProvider = FutureProvider.autoDispose<ChatOverview>((ref) {
  return ref.watch(chatRepositoryProvider).fetchOverview();
});

final chatConfigProvider = FutureProvider.autoDispose
    .family<ChatConfig?, String>((ref, chatMode) {
      return ref.watch(chatRepositoryProvider).fetchConfig(chatMode);
    });

final aiRobotProfilesProvider = FutureProvider.autoDispose
    .family<List<AiRobotProfile>, String>((ref, runtimeMode) {
      return ref.watch(chatRepositoryProvider).fetchRobotProfiles(runtimeMode);
    });

final onlineChatModelsProvider =
    FutureProvider.autoDispose<List<OnlineChatModel>>((ref) {
      return ref.watch(chatRepositoryProvider).fetchOnlineModels();
    });

final chatRecordsProvider = FutureProvider.autoDispose
    .family<ChatPage<ChatRecord>, int>((ref, sessionId) {
      return ref.watch(chatRepositoryProvider).fetchRecords(sessionId);
    });
