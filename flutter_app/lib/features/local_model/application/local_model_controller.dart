import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local_llm/llama_engine.dart';
import '../../../core/local_llm/local_chat_store.dart';
import '../../../core/local_llm/model_downloader.dart';
import '../../../core/local_llm/local_prompt_resolver.dart';
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

final modelDownloaderProvider = Provider<ModelDownloader>((ref) {
  return ModelDownloader(
    ref.watch(apiClientProvider).dio,
    ref.watch(sharedPreferencesProvider),
  );
});

final localChatStoreProvider = Provider<LocalChatStore>((ref) {
  return LocalChatStore(ref.watch(tokenStorageProvider));
});

final llamaEngineProvider = Provider<LlamaEngine>((ref) {
  return const LlamaEngine();
});

final localPromptResolverProvider = Provider<LocalPromptResolver>((ref) {
  return const LocalPromptResolver();
});

final localModelDownloadControllerProvider =
    AsyncNotifierProvider<
      LocalModelDownloadController,
      Map<int, LocalModelDownloadState>
    >(LocalModelDownloadController.new);

class LocalModelDownloadController
    extends AsyncNotifier<Map<int, LocalModelDownloadState>> {
  @override
  Future<Map<int, LocalModelDownloadState>> build() async {
    final catalog = await ref.watch(localModelCatalogProvider.future);
    final memberId = await _memberId();
    final downloader = ref.watch(modelDownloaderProvider);
    final states = <int, LocalModelDownloadState>{};

    for (final model in catalog) {
      states[model.id] = await downloader.readState(model, memberId: memberId);
    }

    return states;
  }

  Future<void> download(LocalModelItem model) async {
    final memberId = await _memberId();
    final downloader = ref.read(modelDownloaderProvider);

    _setModelState(model.id, const LocalModelDownloadState.downloading(0));
    try {
      final result = await downloader.download(
        model,
        memberId: memberId,
        onProgress: (progress) {
          _setModelState(
            model.id,
            LocalModelDownloadState.downloading(progress),
          );
        },
        onVerifying: () {
          _setModelState(model.id, const LocalModelDownloadState.verifying());
        },
      );
      _setModelState(model.id, result);
    } on Object catch (error) {
      _setModelState(
        model.id,
        LocalModelDownloadState.failed(error.toString()),
      );
      rethrow;
    }
  }

  Future<void> delete(LocalModelItem model) async {
    final memberId = await _memberId();
    await ref
        .read(modelDownloaderProvider)
        .deleteModel(model, memberId: memberId);
    _setModelState(model.id, const LocalModelDownloadState.notDownloaded());
  }

  void _setModelState(int modelId, LocalModelDownloadState modelState) {
    final current = state.hasValue
        ? state.value ?? const <int, LocalModelDownloadState>{}
        : const <int, LocalModelDownloadState>{};
    state = AsyncValue.data({...current, modelId: modelState});
  }

  Future<String> _memberId() async {
    return await ref.read(tokenStorageProvider).readMemberId() ?? 'anonymous';
  }
}
