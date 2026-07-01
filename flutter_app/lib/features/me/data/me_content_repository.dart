import '../../../core/api/api_client.dart';
import 'me_content_models.dart';

class MeContentRepository {
  const MeContentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<MePage<JournalEntry>> fetchJournals({
    int page = 1,
    int pageSize = 100,
  }) async {
    final result = await _apiClient.getApi<MePage<JournalEntry>>(
      '/app/help/me/journals',
      queryParameters: {'page': page, 'page_size': pageSize},
      decode: (value) => MePage.fromJson(value, JournalEntry.fromJson),
    );
    return result.data ??
        const MePage(list: [], total: 0, page: 1, pageSize: 100);
  }

  Future<JournalEntry> saveJournal({
    int? id,
    required String entryDate,
    required String entryTime,
    required String title,
    required String content,
  }) async {
    final result = await _apiClient.postApi<JournalEntry>(
      '/app/help/me/journal',
      data: {
        if (id != null && id > 0) 'id': id,
        'entry_date': entryDate,
        if (entryTime.trim().isNotEmpty) 'entry_time': entryTime,
        'title': title,
        'content': content,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return JournalEntry.fromJson(value);
        }
        throw const FormatException('Unexpected journal shape');
      },
    );
    final entry = result.data;
    if (entry == null || entry.id <= 0) {
      throw const FormatException('日记保存失败');
    }
    return entry;
  }

  Future<void> deleteJournal(int id) async {
    await _apiClient.postApi<Map<String, dynamic>>(
      '/app/help/me/journal/delete',
      data: {'id': id},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value;
        }
        return const {};
      },
    );
  }

  Future<MePage<MemoirItem>> fetchMemoirs({
    String sourceMonth = '',
    int page = 1,
    int pageSize = 50,
  }) async {
    final result = await _apiClient.getApi<MePage<MemoirItem>>(
      '/app/help/me/memoirs',
      queryParameters: {
        if (sourceMonth.trim().isNotEmpty) 'source_month': sourceMonth.trim(),
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) => MePage.fromJson(value, MemoirItem.fromJson),
    );
    return result.data ??
        const MePage(list: [], total: 0, page: 1, pageSize: 50);
  }

  Future<MemoirItem> fetchMemoirDetail(int id) async {
    final result = await _apiClient.getApi<MemoirItem>(
      '/app/help/me/memoir',
      queryParameters: {'id': id},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return MemoirItem.fromJson(value);
        }
        throw const FormatException('Unexpected memoir detail shape');
      },
    );
    final item = result.data;
    if (item == null || item.id <= 0) {
      throw const FormatException('回忆录不存在');
    }
    return item;
  }

  Future<List<MemoirConfig>> fetchMemoirConfigs() async {
    final result = await _apiClient.getApi<List<MemoirConfig>>(
      '/app/help/me/memoir-configs',
      decode: (value) {
        if (value is! Map<String, dynamic>) {
          return const [];
        }
        final list = value['list'];
        if (list is! List) {
          return const [];
        }
        return list
            .whereType<Map<String, dynamic>>()
            .map(MemoirConfig.fromJson)
            .toList(growable: false);
      },
    );
    return result.data ?? const [];
  }

  Future<MemoirItem> generateMemoir({int? configId}) async {
    final result = await _apiClient.postApi<MemoirItem>(
      '/app/help/me/memoir/generate',
      data: {if (configId != null && configId > 0) 'config_id': configId},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          final memoir = value['memoir'];
          if (memoir is Map<String, dynamic>) {
            return MemoirItem.fromJson(memoir);
          }
        }
        throw const FormatException('Unexpected memoir generation shape');
      },
    );
    final item = result.data;
    if (item == null || item.id <= 0) {
      throw const FormatException('回忆录生成失败');
    }
    return item;
  }

  Future<MePage<MemberBadge>> fetchBadges({
    int status = 1,
    int page = 1,
    int pageSize = 50,
  }) async {
    final result = await _apiClient.getApi<MePage<MemberBadge>>(
      '/app/help/me/badges',
      queryParameters: {'status': status, 'page': page, 'page_size': pageSize},
      decode: (value) => MePage.fromJson(value, MemberBadge.fromJson),
    );
    return result.data ??
        const MePage(list: [], total: 0, page: 1, pageSize: 50);
  }

  Future<PointLogPage> fetchPointLogs({
    String changeType = '',
    String sourceType = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _apiClient.getApi<PointLogPage>(
      '/app/help/me/points',
      queryParameters: {
        if (changeType.trim().isNotEmpty) 'change_type': changeType.trim(),
        if (sourceType.trim().isNotEmpty) 'source_type': sourceType.trim(),
        'page': page,
        'page_size': pageSize,
      },
      decode: PointLogPage.fromJson,
    );
    return result.data ??
        const PointLogPage(
          list: [],
          total: 0,
          page: 1,
          pageSize: 20,
          balance: 0,
        );
  }
}
