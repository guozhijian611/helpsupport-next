import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/me_content_models.dart';
import '../data/me_content_repository.dart';

final meContentRepositoryProvider = Provider<MeContentRepository>((ref) {
  return MeContentRepository(ref.watch(apiClientProvider));
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

final pointLogsProvider = FutureProvider.autoDispose<PointLogPage>((ref) {
  return ref.watch(meContentRepositoryProvider).fetchPointLogs();
});
