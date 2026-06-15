import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/material_models.dart';
import '../data/material_repository.dart';

final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  return MaterialRepository(ref.watch(apiClientProvider));
});

final materialCategoriesProvider = FutureProvider.autoDispose
    .family<List<MaterialCategory>, String>((ref, type) {
      return ref.watch(materialRepositoryProvider).fetchCategories(type: type);
    });

final materialListProvider = FutureProvider.autoDispose
    .family<MaterialPage<MaterialItem>, MaterialListQuery>((ref, query) {
      return ref
          .watch(materialRepositoryProvider)
          .fetchMaterials(
            materialType: query.materialType,
            categoryId: query.categoryId,
            keyword: query.keyword,
            page: query.page,
            pageSize: query.pageSize,
          );
    });

final materialCollectionsProvider = FutureProvider.autoDispose
    .family<MaterialPage<MaterialItem>, MaterialHistoryQuery>((ref, query) {
      return ref
          .watch(materialRepositoryProvider)
          .fetchCollections(page: query.page, pageSize: query.pageSize);
    });

final materialHistoryProvider = FutureProvider.autoDispose
    .family<MaterialPage<MaterialHistoryEntry>, MaterialHistoryQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(materialRepositoryProvider)
          .fetchHistory(page: query.page, pageSize: query.pageSize);
    });

final materialDetailProvider = FutureProvider.autoDispose
    .family<MaterialItem, int>((ref, id) {
      return ref.watch(materialRepositoryProvider).fetchMaterialDetail(id);
    });

final materialCommentsProvider = FutureProvider.autoDispose
    .family<MaterialPage<MaterialComment>, int>((ref, materialId) {
      return ref
          .watch(materialRepositoryProvider)
          .fetchComments(materialId: materialId);
    });
