import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'me_content_models.dart';

class LocalJournalStore {
  const LocalJournalStore();

  Future<List<JournalEntry>> list(String memberId) async {
    final file = await _file(memberId);
    if (!await file.exists()) {
      return const [];
    }

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }
    final entries = decoded['entries'];
    if (entries is! List) {
      return const [];
    }

    return entries
        .whereType<Map<String, dynamic>>()
        .map(JournalEntry.fromJson)
        .toList(growable: false);
  }

  Future<bool> hasImported(String memberId) async {
    final file = await _file(memberId);
    if (!await file.exists()) {
      return false;
    }
    final decoded = jsonDecode(await file.readAsString());
    return decoded is Map<String, dynamic> && decoded['imported'] == true;
  }

  Future<JournalEntry> save(String memberId, JournalEntry entry) async {
    final entries = [...await list(memberId)];
    final index = entries.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    entries.sort(_compare);
    await _write(memberId, entries, imported: true);
    return entry;
  }

  Future<void> replaceAll(
    String memberId,
    List<JournalEntry> entries, {
    required bool imported,
  }) async {
    final next = [...entries]..sort(_compare);
    await _write(memberId, next, imported: imported);
  }

  Future<void> delete(String memberId, int id) async {
    final entries = [...await list(memberId)]
      ..removeWhere((item) => item.id == id);
    await _write(memberId, entries, imported: true);
  }

  int _compare(JournalEntry left, JournalEntry right) {
    final date = right.entryDate.compareTo(left.entryDate);
    if (date != 0) {
      return date;
    }
    final time = right.entryTime.compareTo(left.entryTime);
    if (time != 0) {
      return time;
    }
    return right.id.compareTo(left.id);
  }

  Future<void> _write(
    String memberId,
    List<JournalEntry> entries, {
    required bool imported,
  }) async {
    final file = await _file(memberId);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'imported': imported,
        'entries': entries.map((item) => item.toJson()).toList(growable: false),
      }),
    );
  }

  Future<File> _file(String memberId) async {
    final documents = await getApplicationDocumentsDirectory();
    final safeId = memberId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File('${documents.path}/helpsupport_journals/$safeId.json');
  }
}
