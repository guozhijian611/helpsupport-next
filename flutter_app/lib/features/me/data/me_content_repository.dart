import '../../../core/api/api_client.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/settings/privacy_preferences.dart';
import 'local_journal_store.dart';
import 'me_content_models.dart';

class MeContentRepository {
  const MeContentRepository(
    this._apiClient, {
    required SecureTokenStorage tokenStorage,
    required LocalJournalStore journalStore,
    required PrivacyPreferences privacyPreferences,
  }) : _tokenStorage = tokenStorage,
       _journalStore = journalStore,
       _privacyPreferences = privacyPreferences;

  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;
  final LocalJournalStore _journalStore;
  final PrivacyPreferences _privacyPreferences;

  Future<MePage<JournalEntry>> fetchJournals({
    int page = 1,
    int pageSize = 100,
  }) async {
    final memberId = await _requireMemberId();
    await _importLegacyJournalsIfNeeded(memberId);
    final entries = await _journalStore.list(memberId);
    return MePage(
      list: entries,
      total: entries.length,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<JournalEntry> saveJournal({
    int? id,
    required String entryDate,
    required String entryTime,
    required String title,
    required String content,
  }) async {
    final memberId = await _requireMemberId();
    final memberIdValue = int.tryParse(memberId) ?? 0;
    JournalEntry? existing;
    if (id != null && id > 0) {
      for (final item in await _journalStore.list(memberId)) {
        if (item.id == id) {
          existing = item;
          break;
        }
      }
    }
    final now = DateTime.now();
    final entry = JournalEntry(
      id: existing?.id ?? ((id != null && id > 0) ? id : now.microsecondsSinceEpoch),
      memberId: existing?.memberId ?? memberIdValue,
      entryDate: entryDate,
      entryTime: entryTime,
      title: title,
      content: content,
      media: existing?.media ?? const [],
      moodScore: existing?.moodScore ?? 0,
      isPrivate: existing?.isPrivate ?? true,
      aiAccess: existing?.aiAccess ?? false,
      createTime: (existing?.createTime.trim().isNotEmpty ?? false)
          ? existing!.createTime
          : now.toIso8601String(),
    );
    final saved = await _journalStore.save(memberId, entry);
    await _syncJournalSummary(saved);
    return saved;
  }

  Future<void> deleteJournal(int id) async {
    final memberId = await _requireMemberId();
    await _journalStore.delete(memberId, id);
    if (!_privacyPreferences.syncDiarySummary) {
      return;
    }
    try {
      await _apiClient.postApi<Map<String, dynamic>>(
        '/app/help/me/journal/delete',
        data: {'local_id': id},
        decode: (value) {
          if (value is Map<String, dynamic>) {
            return value;
          }
          return const {};
        },
      );
    } catch (_) {
      // 本地日记已删除，摘要同步失败不回滚原文。
    }
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

  Future<String> _requireMemberId() async {
    final memberId = await _tokenStorage.readMemberId();
    if (memberId == null || memberId.trim().isEmpty) {
      throw const FormatException('请先登录后再写日记');
    }
    return memberId.trim();
  }

  Future<void> _importLegacyJournalsIfNeeded(String memberId) async {
    if (await _journalStore.hasImported(memberId)) {
      return;
    }

    final local = await _journalStore.list(memberId);
    if (local.isNotEmpty) {
      await _journalStore.replaceAll(memberId, local, imported: true);
      return;
    }

    try {
      final result = await _apiClient.getApi<MePage<JournalEntry>>(
        '/app/help/me/journals',
        queryParameters: {'page': 1, 'page_size': 200},
        decode: (value) => MePage.fromJson(value, JournalEntry.fromJson),
      );
      final remote = result.data?.list ?? const <JournalEntry>[];
      await _journalStore.replaceAll(
        memberId,
        remote
            .map(
              (item) => item.id > 0
                  ? item
                  : item.copyWith(id: DateTime.now().microsecondsSinceEpoch),
            )
            .toList(growable: false),
        imported: true,
      );
    } catch (_) {
      // 网络失败时不标记已导入，下次打开再尝试拉取旧云端日记。
    }
  }

  Future<void> _syncJournalSummary(JournalEntry entry) async {
    if (!_privacyPreferences.syncDiarySummary) {
      return;
    }
    try {
      await _apiClient.postApi<Map<String, dynamic>>(
        '/app/help/me/journal',
        data: {
          'local_id': entry.id,
          'entry_date': entry.entryDate,
          if (entry.entryTime.trim().isNotEmpty) 'entry_time': entry.entryTime,
          'mood_score': entry.moodScore,
          'word_count': _journalWordCount(entry),
          'summary': _journalSummary(entry),
        },
        decode: (value) {
          if (value is Map<String, dynamic>) {
            return value;
          }
          return const {};
        },
      );
    } catch (_) {
      // 原文已落本地，摘要同步失败不回滚。
    }
  }

  int _journalWordCount(JournalEntry entry) {
    return '${entry.title} ${entry.content}'.replaceAll(RegExp(r'\s+'), '').length;
  }

  String _journalSummary(JournalEntry entry) {
    final wordCount = _journalWordCount(entry);
    if (wordCount <= 0) {
      return '当天写了一篇日记';
    }
    return '当天写了一篇约 $wordCount 字的日记';
  }
}
