import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import 'material_models.dart';

class MaterialMusicSupport {
  const MaterialMusicSupport._();

  static bool isAudioItem(MaterialItem item) {
    return isAudioMediaType(item.mediaType);
  }

  static bool isAudioMediaType(String mediaType) {
    final type = mediaType.trim().toLowerCase();
    return type == 'audio' || type == 'mp3';
  }

  static String resolveContentUrl(ApiClient apiClient, MaterialItem item) {
    return apiClient.resolveUrl(item.contentUrl).trim();
  }

  static Future<bool> hasCachedResource(
    ApiClient apiClient,
    MaterialItem item,
  ) async {
    final resourceUrl = resolveContentUrl(apiClient, item);
    if (resourceUrl.isEmpty) {
      return false;
    }
    final file = await cacheFileFor(item, resourceUrl);
    return file.exists();
  }

  static Future<File> cacheFileFor(
    MaterialItem item,
    String resourceUrl,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final extension = _resourceExtension(item, resourceUrl);
    return File('${directory.path}/material_cache/${item.id}.$extension');
  }

  static Future<File?> cacheRemoteFile({
    required ApiClient apiClient,
    required String resourceUrl,
    required File localFile,
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.tryParse(resourceUrl);
    if (uri == null || !uri.hasScheme) {
      return null;
    }
    await localFile.parent.create(recursive: true);
    try {
      await apiClient.dio.download(
        resourceUrl,
        localFile.path,
        onReceiveProgress: (received, total) {
          if (onProgress == null || total <= 0) {
            return;
          }
          onProgress((received * 100 / total).clamp(0, 100));
        },
      );
      return localFile;
    } on Object {
      if (await localFile.exists()) {
        await localFile.delete();
      }
      return null;
    }
  }

  static Future<String> loadLyrics(
    ApiClient apiClient,
    MaterialItem item,
  ) async {
    final lyricUrl = apiClient.resolveUrl(item.lyricUrl).trim();
    if (lyricUrl.isEmpty) {
      return item.contentText;
    }
    try {
      final response = await apiClient.dio.get<String>(
        lyricUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final content = (response.data ?? '').trim();
      return content.isEmpty ? item.contentText : content;
    } on Object {
      return item.contentText;
    }
  }

  static Duration positionFromHistoryProgress(
    Duration? duration,
    double progress,
  ) {
    if (duration == null || duration.inMilliseconds <= 0 || progress <= 0) {
      return Duration.zero;
    }
    final percent = progress.clamp(0, 100).toDouble();
    return Duration(
      milliseconds: (duration.inMilliseconds * percent / 100).round(),
    );
  }

  static String formatDuration(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final totalSeconds = safeDuration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static List<MaterialLyricLine> parseLyrics(String source) {
    final lines = <MaterialLyricLine>[];
    final timestampPattern = RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]');
    for (final rawLine in const LineSplitter().convert(source)) {
      final matches = timestampPattern.allMatches(rawLine).toList();
      final text = rawLine.replaceAll(timestampPattern, '').trim();
      if (matches.isEmpty) {
        if (text.isNotEmpty && !rawLine.trim().startsWith('[')) {
          lines.add(MaterialLyricLine(time: null, text: text));
        }
        continue;
      }
      if (text.isEmpty) {
        continue;
      }
      for (final match in matches) {
        lines.add(
          MaterialLyricLine(time: _durationFromLrcMatch(match), text: text),
        );
      }
    }
    lines.sort((left, right) {
      final leftTime = left.time;
      final rightTime = right.time;
      if (leftTime == null && rightTime == null) {
        return 0;
      }
      if (leftTime == null) {
        return 1;
      }
      if (rightTime == null) {
        return -1;
      }
      return leftTime.compareTo(rightTime);
    });
    return lines;
  }

  static int activeLyricIndex(
    List<MaterialLyricLine> lines,
    Duration position,
  ) {
    var activeIndex = -1;
    for (var index = 0; index < lines.length; index += 1) {
      final time = lines[index].time;
      if (time == null) {
        continue;
      }
      if (time > position) {
        break;
      }
      activeIndex = index;
    }
    return activeIndex;
  }

  static Duration _durationFromLrcMatch(RegExpMatch match) {
    final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
    final seconds = int.tryParse(match.group(2) ?? '') ?? 0;
    final fraction = match.group(3) ?? '';
    final milliseconds = switch (fraction.length) {
      0 => 0,
      1 => int.parse(fraction) * 100,
      2 => int.parse(fraction) * 10,
      _ => int.parse(fraction.substring(0, 3)),
    };
    return Duration(
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }

  static String _resourceExtension(MaterialItem item, String resourceUrl) {
    final type = item.mediaType.trim().toLowerCase();
    if (type == 'video') {
      return _extensionFromUrl(resourceUrl, 'mp4');
    }
    if (type == 'audio') {
      return _extensionFromUrl(resourceUrl, 'mp3');
    }
    if (type.isNotEmpty &&
        type != 'article' &&
        type != 'link' &&
        type != 'game') {
      return type;
    }
    return _extensionFromUrl(resourceUrl, 'html');
  }

  static String _extensionFromUrl(String resourceUrl, String fallback) {
    final uri = Uri.tryParse(resourceUrl);
    final path = uri?.path ?? '';
    final dot = path.lastIndexOf('.');
    if (dot >= 0 && dot < path.length - 1) {
      final extension = path
          .substring(dot + 1)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (extension.isNotEmpty) {
        return extension.length > 12 ? extension.substring(0, 12) : extension;
      }
    }
    return fallback;
  }
}

class MaterialLyricLine {
  const MaterialLyricLine({required this.time, required this.text});

  final Duration? time;
  final String text;
}
