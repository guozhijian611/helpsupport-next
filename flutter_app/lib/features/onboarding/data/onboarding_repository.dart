import '../../../core/api/api_client.dart';
import 'onboarding_models.dart';

class OnboardingRepository {
  const OnboardingRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<OnboardingPage>> fetchPages(OnboardingQuery query) async {
    final result = await _apiClient.getApi<List<OnboardingPage>>(
      '/app/help/common/onboarding',
      queryParameters: query.toQueryParameters(),
      decode: _decodeList,
    );
    return result.data ?? const [];
  }

  List<OnboardingPage> _decodeList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(OnboardingPage.fromJson)
        .map((page) => page.copyWith(image: _apiClient.resolveUrl(page.image)))
        .toList(growable: false);
  }
}
