import '../../../core/api/api_client.dart';
import 'local_model_models.dart';

class LocalModelRepository {
  const LocalModelRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<LocalModelItem>> fetchCatalog() async {
    final result = await _apiClient.getApi<List<LocalModelItem>>(
      '/app/help/local-model/catalog',
      decode: (value) => _decodeList(value, LocalModelItem.fromJson),
    );
    return result.data ?? const [];
  }

  Future<List<LocalModelPrompt>> fetchPrompts({required String locale}) async {
    final result = await _apiClient.getApi<List<LocalModelPrompt>>(
      '/app/help/local-model/prompts',
      queryParameters: {'locale': locale},
      decode: (value) => _decodeList(value, LocalModelPrompt.fromJson),
    );
    return result.data ?? const [];
  }

  List<T> _decodeList<T>(
    Object? value,
    T Function(Map<String, dynamic> json) decode,
  ) {
    if (value is! List) {
      return const [];
    }

    return value.whereType<Map<String, dynamic>>().map(decode).toList();
  }
}
