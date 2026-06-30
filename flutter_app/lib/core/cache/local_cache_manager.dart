import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalCacheSnapshot {
  const LocalCacheSnapshot({
    required this.fileCount,
    required this.totalBytes,
    this.oldestModifiedAt,
  });

  final int fileCount;
  final int totalBytes;
  final DateTime? oldestModifiedAt;

  bool get isEmpty => fileCount == 0 || totalBytes <= 0;
}

class LocalCacheClearResult {
  const LocalCacheClearResult({
    required this.deletedFileCount,
    required this.deletedBytes,
    required this.remaining,
  });

  final int deletedFileCount;
  final int deletedBytes;
  final LocalCacheSnapshot remaining;
}

class LocalCacheManager {
  const LocalCacheManager();

  static const autoClearAge = Duration(days: 7);
  static const autoClearInterval = Duration(hours: 24);

  Future<LocalCacheSnapshot> inspect({Duration? olderThan}) async {
    final entries = await _collectEntries(olderThan: olderThan);
    return _snapshotFromEntries(entries);
  }

  Future<LocalCacheClearResult> clear({Duration? olderThan}) async {
    final entries = await _collectEntries(olderThan: olderThan);
    var deletedFileCount = 0;
    var deletedBytes = 0;

    for (final entry in entries) {
      try {
        await entry.file.delete();
        deletedFileCount += 1;
        deletedBytes += entry.bytes;
      } on FileSystemException {
        // Some temporary media files can disappear while the OS is reclaiming
        // storage. They are ignored because the cache pass is best-effort.
      }
    }

    await _pruneEmptyCacheDirectories();
    final remaining = await inspect();
    return LocalCacheClearResult(
      deletedFileCount: deletedFileCount,
      deletedBytes: deletedBytes,
      remaining: remaining,
    );
  }

  Future<List<_CacheFileEntry>> _collectEntries({Duration? olderThan}) async {
    final roots = await _cacheRoots();
    final cutoff = olderThan == null
        ? null
        : DateTime.now().subtract(olderThan);
    final entries = <_CacheFileEntry>[];

    for (final root in roots) {
      if (!await root.directory.exists()) {
        continue;
      }
      await for (final entity in root.directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File || !root.includes(entity)) {
          continue;
        }
        try {
          final stat = await entity.stat();
          if (stat.type != FileSystemEntityType.file) {
            continue;
          }
          if (cutoff != null && stat.modified.isAfter(cutoff)) {
            continue;
          }
          entries.add(
            _CacheFileEntry(
              file: entity,
              bytes: stat.size,
              modifiedAt: stat.modified,
            ),
          );
        } on FileSystemException {
          // Ignore files that are removed or locked during traversal.
        }
      }
    }

    return entries;
  }

  Future<List<_CacheRoot>> _cacheRoots() async {
    final documents = await getApplicationDocumentsDirectory();
    final temporary = await getTemporaryDirectory();
    return [
      _CacheRoot(
        directory: Directory('${documents.path}/material_cache'),
        includes: (_) => true,
        pruneEmptyDirectories: true,
      ),
      _CacheRoot(
        directory: temporary,
        includes: _isPickedTemporaryMedia,
        pruneEmptyDirectories: false,
      ),
    ];
  }

  Future<void> _pruneEmptyCacheDirectories() async {
    final roots = await _cacheRoots();
    for (final root in roots) {
      if (!root.pruneEmptyDirectories) {
        continue;
      }
      if (!await root.directory.exists()) {
        continue;
      }
      await _deleteEmptyChildren(root.directory, keepRoot: true);
    }
  }

  Future<bool> _deleteEmptyChildren(
    Directory directory, {
    required bool keepRoot,
  }) async {
    var hasChildren = false;
    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is Directory) {
          final childDeleted = await _deleteEmptyChildren(
            entity,
            keepRoot: false,
          );
          hasChildren = hasChildren || !childDeleted;
        } else {
          hasChildren = true;
        }
      }
      if (!keepRoot && !hasChildren) {
        await directory.delete();
        return true;
      }
    } on FileSystemException {
      return false;
    }
    return false;
  }

  LocalCacheSnapshot _snapshotFromEntries(List<_CacheFileEntry> entries) {
    var totalBytes = 0;
    DateTime? oldestModifiedAt;
    for (final entry in entries) {
      totalBytes += entry.bytes;
      final currentOldest = oldestModifiedAt;
      if (currentOldest == null || entry.modifiedAt.isBefore(currentOldest)) {
        oldestModifiedAt = entry.modifiedAt;
      }
    }
    return LocalCacheSnapshot(
      fileCount: entries.length,
      totalBytes: totalBytes,
      oldestModifiedAt: oldestModifiedAt,
    );
  }

  bool _isPickedTemporaryMedia(File file) {
    final name = _basename(file.path).toLowerCase();
    return name.startsWith('image_picker_') ||
        name.startsWith('video_picker_') ||
        name.startsWith('scaled_') ||
        name.startsWith('thumb_') ||
        name.startsWith('thumbnail_');
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index == -1 ? normalized : normalized.substring(index + 1);
  }
}

class _CacheRoot {
  const _CacheRoot({
    required this.directory,
    required this.includes,
    required this.pruneEmptyDirectories,
  });

  final Directory directory;
  final bool Function(File file) includes;
  final bool pruneEmptyDirectories;
}

class _CacheFileEntry {
  const _CacheFileEntry({
    required this.file,
    required this.bytes,
    required this.modifiedAt,
  });

  final File file;
  final int bytes;
  final DateTime modifiedAt;
}
