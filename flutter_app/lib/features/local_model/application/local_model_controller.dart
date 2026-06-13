import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/local_model_models.dart';
import '../data/local_model_repository.dart';

final localModelRepositoryProvider = Provider<LocalModelRepository>((ref) {
  return LocalModelRepository(ref.watch(apiClientProvider));
});

final localModelCatalogProvider =
    FutureProvider.autoDispose<List<LocalModelItem>>((ref) {
      return ref.watch(localModelRepositoryProvider).fetchCatalog();
    });

final localModelPromptsProvider = FutureProvider.autoDispose
    .family<List<LocalModelPrompt>, String>((ref, locale) {
      return ref
          .watch(localModelRepositoryProvider)
          .fetchPrompts(locale: locale);
    });
