import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/api/api_client.dart';
import 'material_models.dart';

class MaterialRepository {
  const MaterialRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<MaterialCategory>> fetchCategories({
    required String type,
    String locale = '',
  }) async {
    final result = await _apiClient.getApi<List<MaterialCategory>>(
      '/app/help/material/categories',
      queryParameters: {
        'type': type,
        if (locale.trim().isNotEmpty) 'locale': locale.trim(),
      },
      decode: (value) => _decodeList(value, MaterialCategory.fromJson),
    );
    return result.data ?? const [];
  }

  Future<MaterialPage<MaterialItem>> fetchMaterials({
    required String materialType,
    int categoryId = 0,
    String mediaType = '',
    String keyword = '',
    String locale = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _apiClient.getApi<MaterialPage<MaterialItem>>(
      '/app/help/material/list',
      queryParameters: {
        'material_type': materialType,
        if (categoryId > 0) 'category_id': categoryId,
        if (mediaType.trim().isNotEmpty) 'media_type': mediaType.trim(),
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        if (locale.trim().isNotEmpty) 'locale': locale.trim(),
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) => MaterialPage.fromJson(value, MaterialItem.fromJson),
    );
    return result.data ??
        const MaterialPage(list: [], total: 0, page: 1, pageSize: 20);
  }

  Future<MaterialItem> fetchMaterialDetail(int id, {String locale = ''}) async {
    final result = await _apiClient.getApi<MaterialItem>(
      '/app/help/material/detail',
      queryParameters: {
        'id': id,
        if (locale.trim().isNotEmpty) 'locale': locale.trim(),
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return MaterialItem.fromJson(value);
        }
        throw const FormatException('Unexpected material detail shape');
      },
    );
    final item = result.data;
    if (item == null || item.id <= 0) {
      throw const FormatException('素材不存在');
    }
    return item;
  }

  Future<MaterialPage<MaterialItem>> fetchCollections({
    String locale = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _apiClient.getApi<MaterialPage<MaterialItem>>(
      '/app/help/material/collections',
      queryParameters: {
        if (locale.trim().isNotEmpty) 'locale': locale.trim(),
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) => MaterialPage.fromJson(value, MaterialItem.fromJson),
    );
    return result.data ??
        const MaterialPage(list: [], total: 0, page: 1, pageSize: 20);
  }

  Future<MaterialPage<MaterialHistoryEntry>> fetchHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _apiClient.getApi<MaterialPage<MaterialHistoryEntry>>(
      '/app/help/material/history',
      queryParameters: {'page': page, 'page_size': pageSize},
      decode: (value) =>
          MaterialPage.fromJson(value, MaterialHistoryEntry.fromJson),
    );
    return result.data ??
        const MaterialPage(list: [], total: 0, page: 1, pageSize: 20);
  }

  Future<MaterialPage<MaterialComment>> fetchComments({
    required int materialId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _apiClient.getApi<MaterialPage<MaterialComment>>(
      '/app/help/material/comments',
      queryParameters: {
        'material_id': materialId,
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) => MaterialPage.fromJson(value, MaterialComment.fromJson),
    );
    return result.data ??
        const MaterialPage(list: [], total: 0, page: 1, pageSize: 20);
  }

  Future<MaterialComment> createComment({
    required int materialId,
    required String content,
  }) async {
    final result = await _apiClient.postApi<MaterialComment>(
      '/app/help/material/comment',
      data: {'material_id': materialId, 'content': content},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return MaterialComment.fromJson(value);
        }
        throw const FormatException('Unexpected material comment shape');
      },
    );
    final item = result.data;
    if (item == null || item.id <= 0) {
      throw const FormatException('评论发布失败');
    }
    return item;
  }

  Future<bool> toggleLike(int materialId) async {
    final result = await _apiClient.postApi<bool>(
      '/app/help/material/like',
      data: {'material_id': materialId},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value['is_liked'] == true;
        }
        return false;
      },
    );
    return result.data ?? false;
  }

  Future<bool> toggleCollect(int materialId) async {
    final result = await _apiClient.postApi<bool>(
      '/app/help/material/collect',
      data: {'material_id': materialId},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value['is_collected'] == true;
        }
        return false;
      },
    );
    return result.data ?? false;
  }

  Future<bool> toggleCommentLike(int commentId) async {
    final result = await _apiClient.postApi<bool>(
      '/app/help/material/comment/like',
      data: {'comment_id': commentId},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value['is_liked'] == true;
        }
        return false;
      },
    );
    return result.data ?? false;
  }

  Future<MaterialUploadResult> uploadPrivateMaterialFile({
    required PlatformFile file,
  }) async {
    final path = file.path;
    if (path == null || path.trim().isEmpty) {
      throw const FormatException('无法读取本地文件路径');
    }
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(path, filename: file.name),
    });
    final result = await _apiClient.postApi<MaterialUploadResult>(
      '/app/help/material/private/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return MaterialUploadResult.fromJson(value);
        }
        throw const FormatException('Unexpected private material upload shape');
      },
    );
    final upload = result.data;
    if (upload == null || upload.url.trim().isEmpty) {
      throw const FormatException('私人素材上传失败');
    }
    return upload;
  }

  Future<MaterialItem> savePrivateMaterial(Map<String, dynamic> data) async {
    final result = await _apiClient.postApi<MaterialItem>(
      '/app/help/material/private',
      data: data,
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return MaterialItem.fromJson(value);
        }
        throw const FormatException('Unexpected private material shape');
      },
    );
    final item = result.data;
    if (item == null || item.id <= 0) {
      throw const FormatException('私人素材保存失败');
    }
    return item;
  }

  Future<void> saveHistory({
    required int materialId,
    required String title,
    required String route,
    String authorName = '',
    double progress = 0,
    int durationSeconds = 0,
  }) async {
    await _apiClient.postApi<Map<String, dynamic>>(
      '/app/help/material/history/save',
      data: {
        'content_id': materialId,
        'content_type': 'material',
        'title': title,
        'route': route,
        'progress': progress.clamp(0, 100).toStringAsFixed(2),
        if (authorName.trim().isNotEmpty) 'author_name': authorName,
        if (durationSeconds > 0) 'duration_seconds': durationSeconds,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value;
        }
        return const {};
      },
    );
  }

  List<T> _decodeList<T>(
    Object? value,
    T Function(Map<String, dynamic> json) decode,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(decode)
        .toList(growable: false);
  }
}
