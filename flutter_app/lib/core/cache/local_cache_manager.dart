import 'dart:io';

import 'package:path_provider/path_provider.dart';

enum LocalCacheCategory { remoteImages, materialFiles, temporaryMedia }

class LocalCacheCategorySnapshot {
  const LocalCacheCategorySnapshot({
    required this.category,
    required this.fileCount,
    required this.totalBytes,
    this.oldestModifiedAt,
  });

  final LocalCacheCategory category;
  final int fileCount;
  final int totalBytes;
  final DateTime? oldestModifiedAt;

  bool get isEmpty => fileCount == 0 || totalBytes <= 0;
}

class LocalCacheSnapshot {
  const LocalCacheSnapshot({required this.categories});

  final List<LocalCacheCategorySnapshot> categories;

  int get fileCount =>
      categories.fold(0, (total, category) => total + category.fileCount);

  int get totalBytes =>
      categories.fold(0, (total, category) => total + category.totalBytes);

  DateTime? get oldestModifiedAt {
    DateTime? oldest;
    for (final category in categories) {
      final modifiedAt = category.oldestModifiedAt;
      if (modifiedAt == null) {
        continue;
      }
      if (oldest == null || modifiedAt.isBefore(oldest)) {
        oldest = modifiedAt;
      }
    }
    return oldest;
  }

  bool get isEmpty => fileCount == 0 || totalBytes <= 0;

  LocalCacheCategorySnapshot category(LocalCacheCategory category) {
    return categories.firstWhere(
      (item) => item.category == category,
      orElse: () => LocalCacheCategorySnapshot(
        category: category,
        fileCount: 0,
        totalBytes: 0,
      ),
    );
  }

  bool hasAnySelectedCache(Set<LocalCacheCategory> selectedCategories) {
    return selectedCategories.any(
      (category) => !this.category(category).isEmpty,
    );
  }

  factory LocalCacheSnapshot.empty() {
    return LocalCacheSnapshot(
      categories: [
        for (final category in LocalCacheCategory.values)
          LocalCacheCategorySnapshot(
            category: category,
            fileCount: 0,
            totalBytes: 0,
          ),
      ],
    );
  }

  factory LocalCacheSnapshot._fromEntries(List<_CacheFileEntry> entries) {
    return LocalCacheSnapshot(
      categories: [
        for (final category in LocalCacheCategory.values)
          _snapshotCategory(category, entries),
      ],
    );
  }

  static LocalCacheCategorySnapshot _snapshotCategory(
    LocalCacheCategory category,
    List<_CacheFileEntry> entries,
  ) {
    var fileCount = 0;
    var totalBytes = 0;
    DateTime? oldestModifiedAt;

    for (final entry in entries) {
      if (entry.category != category) {
        continue;
      }
      fileCount += 1;
      totalBytes += entry.bytes;
      final currentOldest = oldestModifiedAt;
      if (currentOldest == null || entry.modifiedAt.isBefore(currentOldest)) {
        oldestModifiedAt = entry.modifiedAt;
      }
    }

    return LocalCacheCategorySnapshot(
      category: category,
      fileCount: fileCount,
      totalBytes: totalBytes,
      oldestModifiedAt: oldestModifiedAt,
    );
  }
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

  Future<LocalCacheSnapshot> inspect({
    Duration? olderThan,
    Set<LocalCacheCategory>? categories,
  }) async {
    final entries = await _collectEntries(
      olderThan: olderThan,
      categories: categories,
    );
    return LocalCacheSnapshot._fromEntries(entries);
  }

  Future<LocalCacheClearResult> clear({
    Duration? olderThan,
    Set<LocalCacheCategory>? categories,
  }) async {
    final entries = await _collectEntries(
      olderThan: olderThan,
      categories: categories,
    );
    var deletedFileCount = 0;
    var deletedBytes = 0;

    for (final entry in entries) {
      try {
        await entry.file.delete();
        deletedFileCount += 1;
        deletedBytes += entry.bytes;
      } on FileSystemException {
        // Cache files can disappear while iOS reclaims temporary storage.
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

  Future<List<_CacheFileEntry>> _collectEntries({
    Duration? olderThan,
    Set<LocalCacheCategory>? categories,
  }) async {
    final roots = await _cacheRoots();
    final cutoff = olderThan == null
        ? null
        : DateTime.now().subtract(olderThan);
    final entries = <_CacheFileEntry>[];

    for (final root in roots) {
      if (categories != null && !categories.contains(root.category)) {
        continue;
      }
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
              category: root.category,
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
        category: LocalCacheCategory.remoteImages,
        directory: Directory('${documents.path}/http_image_cache'),
        includes: (_) => true,
        pruneEmptyDirectories: true,
      ),
      _CacheRoot(
        category: LocalCacheCategory.materialFiles,
        directory: Directory('${documents.path}/material_cache'),
        includes: (_) => true,
        pruneEmptyDirectories: true,
      ),
      _CacheRoot(
        category: LocalCacheCategory.temporaryMedia,
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
    required this.category,
    required this.directory,
    required this.includes,
    required this.pruneEmptyDirectories,
  });

  final LocalCacheCategory category;
  final Directory directory;
  final bool Function(File file) includes;
  final bool pruneEmptyDirectories;
}

class _CacheFileEntry {
  const _CacheFileEntry({
    required this.file,
    required this.bytes,
    required this.modifiedAt,
    required this.category,
  });

  final File file;
  final int bytes;
  final DateTime modifiedAt;
  final LocalCacheCategory category;
}
