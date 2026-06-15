import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../providers/app_providers.dart';

class AppConfig {
  const AppConfig({
    required this.name,
    required this.logo,
    required this.description,
    required this.defaultLocale,
    required this.supportedLocales,
  });

  static const fallback = AppConfig(
    name: 'HelpSupport',
    logo: '',
    description: '',
    defaultLocale: 'en-US',
    supportedLocales: ['en-US', 'zh-CN'],
  );

  final String name;
  final String logo;
  final String description;
  final String defaultLocale;
  final List<String> supportedLocales;

  factory AppConfig.fromJson(Object? value, ApiClient apiClient) {
    if (value is! Map<String, dynamic>) {
      return fallback;
    }

    final app = value['app'];
    if (app is! Map<String, dynamic>) {
      return fallback;
    }

    final supportedLocales = app['supported_locales'];

    return AppConfig(
      name: _stringValue(app['name'], fallback.name),
      logo: apiClient.resolveUrl(_stringValue(app['logo'])),
      description: _stringValue(app['description']),
      defaultLocale: _stringValue(
        app['default_locale'],
        fallback.defaultLocale,
      ),
      supportedLocales: supportedLocales is List
          ? supportedLocales
                .map((value) => value.toString().trim())
                .where((value) => value.isNotEmpty)
                .toList(growable: false)
          : fallback.supportedLocales,
    );
  }

  static String _stringValue(Object? value, [String fallback = '']) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class AppConfigRepository {
  const AppConfigRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AppConfig> fetch() async {
    final result = await _apiClient.getApi<AppConfig>(
      '/app/help/common/app-config',
      decode: (value) => AppConfig.fromJson(value, _apiClient),
    );

    return result.data ?? AppConfig.fallback;
  }
}

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepository(ref.watch(apiClientProvider));
});

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  try {
    return await ref.watch(appConfigRepositoryProvider).fetch();
  } on Object {
    return AppConfig.fallback;
  }
});
