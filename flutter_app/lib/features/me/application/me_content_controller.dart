import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/settings/privacy_preferences.dart';
import '../../auth/application/auth_controller.dart';
import '../data/local_journal_store.dart';
import '../data/me_content_models.dart';
import '../data/me_content_repository.dart';

final localJournalStoreProvider = Provider<LocalJournalStore>((ref) {
  return const LocalJournalStore();
});

final meContentRepositoryProvider = Provider<MeContentRepository>((ref) {
  return MeContentRepository(
    ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    journalStore: ref.watch(localJournalStoreProvider),
    privacyPreferences: ref.watch(privacyPreferencesProvider),
  );
});

final journalEntriesProvider = FutureProvider.autoDispose<MePage<JournalEntry>>(
  (ref) {
    return ref.watch(meContentRepositoryProvider).fetchJournals();
  },
);

final memoirItemsProvider = FutureProvider.autoDispose<MePage<MemoirItem>>((
  ref,
) {
  return ref.watch(meContentRepositoryProvider).fetchMemoirs();
});

final memoirDetailProvider = FutureProvider.autoDispose.family<MemoirItem, int>(
  (ref, id) {
    return ref.watch(meContentRepositoryProvider).fetchMemoirDetail(id);
  },
);

final memoirConfigsProvider = FutureProvider.autoDispose<List<MemoirConfig>>((
  ref,
) {
  return ref.watch(meContentRepositoryProvider).fetchMemoirConfigs();
});

final memberBadgesProvider = FutureProvider.autoDispose<MePage<MemberBadge>>((
  ref,
) {
  return ref.watch(meContentRepositoryProvider).fetchBadges();
});

final memberBadgeWallProvider = FutureProvider.autoDispose<MePage<MemberBadge>>(
  (ref) {
    return ref.watch(meContentRepositoryProvider).fetchBadges(pageSize: 200);
  },
);

final liveHonorMemberProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
      try {
        final session = await ref
            .read(authControllerProvider.notifier)
            .refreshCurrentSession();
        return session.member;
      } on Object {
        return ref.read(authControllerProvider).asData?.value?.member;
      }
    });

final pointLogsProvider = FutureProvider.autoDispose<PointLogPage>((ref) {
  return ref.watch(meContentRepositoryProvider).fetchPointLogs();
});

final pointLogListProvider = FutureProvider.autoDispose<PointLogPage>((ref) {
  return ref.watch(meContentRepositoryProvider).fetchPointLogs(pageSize: 100);
});
