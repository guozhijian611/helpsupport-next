import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers/app_providers.dart';
import 'help_center_models.dart';

final helpCenterRepositoryProvider = Provider<HelpCenterRepository>((ref) {
  return HelpCenterRepository(ref.watch(apiClientProvider));
});

final helpCategoriesProvider = FutureProvider<List<HelpCategory>>((ref) {
  return ref.watch(helpCenterRepositoryProvider).fetchCategories();
});

final helpArticleListProvider =
    FutureProvider.family<HelpArticlePage, HelpArticleListQuery>((ref, query) {
      return ref.watch(helpCenterRepositoryProvider).fetchArticles(query);
    });

final helpArticleDetailProvider = FutureProvider.family<HelpArticleDetail, int>(
  (ref, articleId) {
    return ref.watch(helpCenterRepositoryProvider).fetchArticle(articleId);
  },
);

class HelpCenterRepository {
  const HelpCenterRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<HelpCategory>> fetchCategories() async {
    final result = await _apiClient.getApi<List<HelpCategory>>(
      '/app/saiuser/api/cms/Article/category',
      decode: (value) {
        if (value is! List) {
          return const [];
        }
        return value
            .whereType<Map<String, dynamic>>()
            .map(HelpCategory.fromJson)
            .where((item) => item.id > 0 && item.name.isNotEmpty)
            .toList(growable: false);
      },
    );
    return result.data ?? const [];
  }

  Future<HelpArticlePage> fetchArticles(HelpArticleListQuery query) async {
    final result = await _apiClient.getApi<HelpArticlePage>(
      '/app/saiuser/api/cms/Article/articles',
      queryParameters: {
        if (query.categoryId > 0) 'category_id': query.categoryId,
        'page': query.page,
        'limit': query.pageSize,
      },
      decode: HelpArticlePage.fromJson,
    );
    return result.data ??
        const HelpArticlePage(list: [], total: 0, page: 1, pageSize: 10);
  }

  Future<HelpArticleDetail> fetchArticle(int articleId) async {
    final result = await _apiClient.getApi<HelpArticleDetail>(
      '/app/saiuser/api/cms/Article/article',
      queryParameters: {'id': articleId},
      decode: HelpArticleDetail.fromJson,
    );
    final article = result.data;
    if (article == null || article.id <= 0) {
      throw const FormatException('帮助内容不存在');
    }
    return article;
  }
}

class HelpArticleListQuery {
  const HelpArticleListQuery({
    required this.categoryId,
    this.page = 1,
    this.pageSize = 20,
  });

  final int categoryId;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HelpArticleListQuery &&
            other.categoryId == categoryId &&
            other.page == page &&
            other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(categoryId, page, pageSize);
}
